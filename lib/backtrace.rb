#--
# Backtrace v1.1 by Solistra
# =============================================================================
# 
# Summary
# -----------------------------------------------------------------------------
#   This script provides the missing full error backtrace for RGSS3 as well as
# a number of features related to exception handling for debugging.
# 
#   Normally, the error message given when an exception is encountered provides
# only the exception information without providing the backtrace; this script
# rectifies that by displaying the backtrace within the RGSS Console when
# applicable, potentially logging the backtrace to a file, and allowing script
# developers to test games with critical bugs without causing the entire engine
# to crash by optionally swallowing all exceptions.
# 
# License
# -----------------------------------------------------------------------------
#   This script is made available under the terms of the MIT Expat license.
# View [this page](http://sesvxace.wordpress.com/license/) for more detailed
# information.
# 
# Installation
# -----------------------------------------------------------------------------
#   Place this script anywhere below the SES Core (v2.0 or higher) script (if
# you are using it) or the Materials header, but above Main. This script does
# not require the SES Core, but it is highly recommended.
# 
#   Place this script below any script which aliases or overwrites the
# `Game_Interpreter#update` or `SceneManager.run` methods for maximum
# compatibility.
# 
#++

# SES
# =============================================================================
# The top-level namespace for all SES scripts.
module SES
  # Backtrace
  # ===========================================================================
  # Provides methods and configuration options for the full error backtrace.
  module Backtrace
    # =========================================================================
    # BEGIN CONFIGURATION
    # =========================================================================
    
    # Whether or not to explicitly raise exceptions after exception handling
    # has taken place; by default, this is set to `true`.
    # 
    # This script will attempt to work around any exceptions raised if this
    # constant is set to a `false` value; this may be useful for script authors
    # or game developers for debugging purposes, but may cause game instability
    # (or other odd behaviors).
    # 
    # **It is highly recommended that you set this constant to `false` before
    # releasing any version of your project.**
    RAISE_EXCEPTIONS = true
    
    # Whether or not to log exception information and the backtrace to a log
    # file; may be either `true` or `false`.
    LOG_EXCEPTIONS = false
    
    # Whether to append to the log file or overwrite previous contents whenever
    # an exception is handled; set to `true` to append to the log file, `false`
    # to overwrite its contents. The value of this constant only applies if
    # {LOG_EXCEPTIONS} has been set to a `true` value.
    APPEND_LOG = true
    
    # The log file exception information is written to if the {LOG_EXCEPTIONS}
    # constant is set to a `true` value. The placement of this file is relative
    # to your project's root directory.
    LOG_FILE = 'Backtrace.log'
    
    # Creates an alert box containing information about a caught exception when
    # one is handled if {RAISE_EXCEPTIONS} is set to a `false` value. This may
    # be useful to alert developers or play testers at the exact moment an
    # exception occurs.
    ALERT = false
    
    # =========================================================================
    # END CONFIGURATION
    # =========================================================================
    
    # Runs the given block, handling all encountered exceptions. The exact form
    # of the exception handling is largely configured via the constants defined
    # in the {SES::Backtrace} module.
    # 
    # @return [Object] the return value of the given block
    def self.with_exception_handling
      yield
    rescue RGSSReset
      # NOTE: This block assumes that `rgss_main` has the default block given
      # to it by the editor -- this is generally a reasonable assumption.
      Graphics.transition(10)
      SceneManager.run
    rescue SystemExit
      exit
    rescue Exception => ex
      print_caught(ex) if $TEST
      File.open(LOG_FILE, APPEND_LOG ? 'a' : 'w') do |file|
        print_caught(ex, file)
      end if LOG_EXCEPTIONS
      if RAISE_EXCEPTIONS
        raise(ex)
      else
        alert_caught(ex) if ALERT
        retry
      end
    end
    
    # Prints exception information and a full backtrace to a specified stream
    # (standard error by default).
    # 
    # @param exception [Exception] the caught exception
    # @param stream [#puts] the stream to write exception information to
    # @return [void]
    def self.print_caught(exception, stream = STDERR)
      for line in exception.backtrace
        break if line[/^:1:/] # Information past this point is irrelevant.
        (trace ||= []) << line.gsub(/^{(\d+)}/) { $RGSS_SCRIPTS[$1.to_i][1] }
      end
      msg =  Time.now.to_s << ' >> EXCEPTION CAUGHT <<'
      msg << "\n#{exception.class}: #{exception}.\nBacktrace:\n\t"
      stream.puts msg << trace.join("\n\t")
    end
    
    # Provides a message box containing information about a handled exception.
    # 
    # @param exception [Exception] the caught exception
    # @return [void]
    def self.alert_caught(exception)
      msg = "EXCEPTION CAUGHT:\n#{exception}\n\n"
      msg << 'Check the RGSS Console for more information.' if $TEST
      msgbox(msg)
    end
    
    # Register this script with the SES Core if it exists.
    if SES.const_defined?(:Register)
      # Script metadata.
      Description = Script.new(:Backtrace, 1.1, :Solistra)
      Register.enter(Description)
    end
  end
end
# SceneManager
# =============================================================================
# Module handling scene transitions and the running status of the game.
module SceneManager
  # Register the overwritten method only if the SES Core is installed.
  class << self ; overwrite :run if respond_to?(:overwrite) ; end
    
  # The starting point of a running RGSS3 game.
  # 
  # @note This method was overridden out of necessity -- the original method
  #   provides both the entry point _and_ the main loop, making it impossible
  #   to provide exception handling only for the main loop without causing the
  #   game to restart on each handled exception.
  # 
  # @return [void]
  def self.run(*args, &block)
    DataManager.init
    Audio.setup_midi if use_midi?
    @scene = first_scene_class.new
    SES::Backtrace.with_exception_handling { @scene.main while @scene }
  end
end
# Game_Interpreter
# =============================================================================
# The worst class in the entire RGSS3 API. Actually, all of the RGSS APIs.
class Game_Interpreter
  # Aliased to provide a workaround for a potential stack overflow after
  # handling an exception.
  # 
  # @see #update
  alias_method :ses_backtrace_gi_upd, :update
  
  # Updates the execution of this instance of the interpreter each frame.
  # 
  # @note The original method did not take the possibility of a dead fiber into
  #   account; as such, calling `@fiber.resume` on a dead fiber after handling
  #   an exception would cause a new `FiberError` to be raised, eventually
  #   resulting in a stack overflow.
  # 
  # @return [void]
  def update(*args, &block)
    ses_backtrace_gi_upd(*args, &block)
  rescue FiberError
    # The fiber is most likely dead due to exception handling -- increment the
    # index for the interpreter and create a new fiber to interpret event
    # commands.
    @index += 1
    create_fiber
  end
end
