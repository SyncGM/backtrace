#--
# Backtrace v1.3 by Solistra
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
    # **It is highly recommended that you set this constant to `true` before
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
    
    # Whether or not to remove the log file created by a previous play testing
    # session whenever the game is started; this may be useful for developers
    # or play testers to ensure that the generated log files do not grow too
    # large. May be either `true` or `false`.
    RESET_LOG = false
    
    # Creates an alert box containing information about a caught exception when
    # one is handled if {RAISE_EXCEPTIONS} is set to a `false` value. This may
    # be useful to alert developers or play testers at the exact moment an
    # exception occurs.
    ALERT = false
    
    # =========================================================================
    # END CONFIGURATION
    # =========================================================================
    
    # Remove the log file if {RESET_LOG} is set to a `true` value and the log
    # file exists.
    File.delete(LOG_FILE) if RESET_LOG && File.exist?(LOG_FILE)
    
    # Runs the given block, handling all encountered exceptions. The exact form
    # of the exception handling is largely configured via the constants defined
    # in the {SES::Backtrace} module.
    # 
    # @return [Object] the return value of the given block
    def self.with_exception_handling
      yield
    rescue RGSSReset
      reset
    rescue SystemExit
      exit
    rescue Exception => ex
      print_caught(ex) if $TEST
      log_caught(ex) if LOG_EXCEPTIONS
      if RAISE_EXCEPTIONS
        raise(ex)
      else
        alert_caught(ex) if ALERT
        retry
      end
    end
    
    # Resets the game in a manner similar to the way the default `rgss_main`
    # loop handles resetting.
    # 
    # @return [void]
    # @see #reset_block=
    def self.reset
      [Audio, Graphics].each(&:__reset__)
      @reset ? TOPLEVEL_BINDING.instance_exec(&@reset) : SceneManager.run
    end
    
    # Assigns the reset block for this module to the given `Proc` object.
    # 
    # @note This method is automatically called by `rgss_main` -- only call
    #   this manually if you are not using the standard `rgss_main` loop and
    #   wish to customize the behavior of an F12 reset.
    # 
    # @param proc [Proc] the `Proc` to execute when an F12 reset is handled
    # @return [Proc]
    def self.reset_block=(proc)
      @reset = proc
    end
    
    # Returns cleaned backtrace information for a given exception by replacing
    # the file information given by Ace with actual script names rather than
    # their numeric placement in the Ace script editor.
    # 
    # @param exception [Exception] the exception to clean the backtrace for
    # @return [Array<String>] the cleaned backtrace
    def self.clean_backtrace_from(exception)
      exception.backtrace.map do |line|
        line.gsub(/^{(\d+)}/) { $RGSS_SCRIPTS[$1.to_i][1] }
      end
    end
    
    # Prints exception information and a full backtrace to a specified stream
    # (standard error by default).
    # 
    # @param exception [Exception] the caught exception
    # @param stream [#puts] the stream to write exception information to
    # @return [void]
    def self.print_caught(exception, stream = STDERR)
      msg =  Time.now.to_s << ' >> EXCEPTION CAUGHT <<'
      msg << "\n#{exception.class}: #{exception}.\nBacktrace:\n\t"
      stream.puts msg << clean_backtrace_from(exception).join("\n\t")
    end
    
    # Logs exception information and a full backtrace to the log file specified
    # by {LOG_FILE}. Exceptions are appended to the log if the {APPEND_LOG}
    # constant is set to a `true` value, otherwise the log will only contain a
    # record of the last encountered exception.
    # 
    # @note The actual logging of information is done via the {.print_caught}
    #   method.
    # 
    # @param exception [Exception] the caught exception
    # @return [void]
    # @see .print_caught
    def self.log_caught(exception)
      File.open(LOG_FILE, APPEND_LOG ? 'a' : 'w') do |file|
        print_caught(exception, file)
      end
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
      Description = Script.new(:Backtrace, 1.3, :Solistra)
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
# Object
# =============================================================================
# Superclass of all objects except `BasicObject`.
class Object
  # Aliased to automatically assign the given block as the reset block for the
  # {SES::Backtrace} module via {SES::Backtrace.reset_block=}.
  # 
  # @see #rgss_main
  alias_method :ses_backtrace_obj_main, :rgss_main
  
  # Evaluates the provided block one time only.
  # 
  # Detects a reset within a block with a press of the F12 key and returns to
  # the beginning if reset.
  # 
  # @return [void]
  def rgss_main(*args, &block)
    SES::Backtrace.reset_block = block
    ses_backtrace_obj_main(*args, &block)
  end
end
