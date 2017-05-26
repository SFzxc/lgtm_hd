require 'commander'
require 'os'
require 'clipboard'
require 'uri'

module LgtmHD
  class CLI
    include Commander::Methods

    def run
      program :name, LgtmHD::Configuration::PROGRAM_NAME
      program :version, LgtmHD::VERSION
      program :description, LgtmHD::Configuration::DESCRIPTION
      default_command :transform

      command :transform do |c|
        c.syntax = 'lgtm_hd transform <source_uri> <output_uri> [options]'
        c.summary = 'Generate a LGTM image from source_uri (local path or URL) into output folder'
        c.description = ''
        c.example '', 'lgtm_hd export http://domain.com/image.png /path/to/lgtm.png'
        c.option '--clipboard', 'Copy the end result (LGTM image) to OS\'s clipboard'
        c.option '--interactive', 'In case you forgot all these super complexive args and options'

        c.action do |args, options|
          to_clipboard = options.clipboard

          # ARGS validation!
          if args.length == 2
              source_uri = args[0]
              output_uri = args[1]
          elsif options.interactive  # Interactive mode!
            say "-- LGTM Interactive mode --"
            source_uri = ask('Source (URL or Path/to/file): ')
            output_uri = ask('Output Folder (absolute path): ')
            # TODO accept relative path "~/.."
            to_clipboard = agree("Copy to clipboard afterward? [Y/N]")
          else
            raise ArgumentError, "Too few or too many arguments provided. Need 2: source and output URIs."
          end


          # Validate the inputs
          raise "Source is not proper URIs (URL or Path/to/file)" unless source_uri =~ URI::regexp || File.exist?(source_uri)
          raise "Output is not a directory or valid path" unless File.exist?(output_uri) && File.directory?(output_uri)

          file_ext = File.extname(source_uri)
          output_uri = File.join(output_uri, LgtmHD::Configuration::OUTPUT_PREFIX + Time.now.strftime('%Y-%m-%d_%H-%M-%S') + file_ext)

          # Do stuff with our LGTM meme
          say "- Reading and inspecting source"
          meme_generator = MemeGenerator.new(input_image_uri:source_uri, output_image_uri:output_uri)
          say "- Rendering output"
          meme_generator.draw

          # Export and play around with the clipboard
          say "- exporting to file"
          meme_generator.export do |output|
            say "LGTM image has been generated at #{output}."
            if to_clipboard then
              if OS.mac? then
                applescript "set the clipboard to (read (POSIX file \"#{output}\") as GIF picture)"
                say "I see you are using MacOSX. Content of the file has been copied to your clipboard."

                # Apple Script Command reference
                # Sample: `osascript -e 'set the clipboard to (read (POSIX file "#{output}") as JPEG picture)'`
                #
                # Currently Github allow pasting image directly to comment box.
                # However it does not support pure text content produced by pbcopy so we have to use direct Applescript
                # No Universal solution as for now.
                #
                # Apple Script reference: http://www.macosxautomation.com/applescript/imageevents/08.html
              else
                Clipboard.copy(output)
                say "Path to LGTM file has been copied to your clipboard."
              end
            end # end of if to_clipboard
          end # end of meme_generator.export block

        end

      end

      run!
    end
  end
end
