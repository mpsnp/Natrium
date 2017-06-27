require 'fileutils'
require 'optparse'
require 'json'
require_relative './logger.rb'

module Esites
  class IconRibbon
    def run
      iconOriginal = nil
      appiconsetDir = nil
      text = nil
      idioms = 'iphone,ipad'

      ARGV << '-h' if ARGV.empty?
      OptionParser.new do |opts|
        opts.banner = "Usage: " + File.basename($0) + " [options]"
        opts.on('-o', '--original PATH', 'Path to the original (clear) file') { |v| iconOriginal = v }
        opts.on('-a', '--appicon PATH', 'Path to the .appiconset file') { |v| appiconsetDir = v }
        opts.on('-l', '--label TEXT', 'The label on the ribbon') { |v| text = v }
        opts.on('-i', '--idioms IDIOMS', 'Comma separated idioms') { |v| idioms = v }
      end.parse!
      generate(iconOriginal, appiconsetDir, text, idioms)
    end

    def imagemagick_installed
      begin
        imagemagick = `convert --version`
        if not imagemagick.include? "ImageMagick"
          return false
        end
      rescue
        return false
      end
      return true
    end

    def generate(iconOriginal, appiconsetDir, text, idioms)
      idioms = idioms.downcase.sub(' ', '').split(',')
      if idioms.include?('iphone')|| idioms.include?('ipad')
        idioms << 'ios-marketing'
      end
      appiconsetDir = appiconsetDir.gsub(/\/$/, '')
      if !imagemagick_installed
        error "Imagemagick is not installed"
      end

      if iconOriginal == nil
        error "Missing --original"
      elsif appiconsetDir == nil
        error "Missing --appicon"
      end

      if not File.file?(iconOriginal)
        error "Cannot find original icon: #{iconOriginal}"
      end

      if not File.directory?(appiconsetDir)
        error "Cannot find app icon asset directory: #{appiconsetDir}"
      end

      FileUtils.rm_rf Dir.glob("#{appiconsetDir}/*")

      dimensions = []
      max_size = 1024
      tmpFile = "tmp_#{max_size}x#{max_size}.png"
      asset = {
        'iphone' => [
          [29, [2,3]],
          [40, [2,3]],
          [60, [2,3]],
          [20, [2,3]]
        ],
        'ipad' => [
          [29, [1,2]],
          [40, [1,2]],
          [76, [1,2]],
          [83.5, [2]],
          [20, [1,2]]
        ],
        'car' => [
          [60, [2,3]],
        ],
        'ios-marketing' => [
          [1024, [1]]
        ],
        'watch' => [
          [24, [2], { 'subtype' => '38mm', 'role' => 'notificationCenter' }],
          [27.5, [2], { 'subtype' => '42mm', 'role' => 'notificationCenter' }],
          [29, [2,3], { 'role' => 'companionSettings' }],
          [40, [2], { 'subtype' => '38mm', 'role' => 'appLauncher' }],
          [86, [2], { 'subtype' => '38mm', 'role' => 'quickLook' }],
          [98, [2], { 'subtype' => '42mm', 'role' => 'quickLook' }],
        ],
        'mac' => [
          [16, [1,2]],
          [32, [1,2]],
          [128, [1,2]],
          [256, [1,2]],
          [512, [1,2]]
        ]
      }
      assetExport = {
        :images => [],
        :info => {
          :version => 1,
          :author => "xcode"
        },
        :properties => {
          :'pre-rendered' => true
        }
       }

      asset.each do |idiom,array|
        array.each do |a|
          if idioms.include? idiom
            write_asset(idiom, a, assetExport, dimensions)
          end
        end
      end

      system("convert \"#{iconOriginal}\" -resize #{max_size}x#{max_size} \"#{tmpFile}\"")
      if text != nil && text != ""
        h = 0.244 * max_size
        point_size = 0.13333 * max_size
        system("convert -size #{max_size}x#{max_size} xc:skyblue -gravity South\
          -draw \"image over 0,0 0,0 \'#{tmpFile}\'\"\
          -draw \"fill black fill-opacity 0.5 rectangle 0,#{max_size - h} #{max_size},#{max_size}\"\
          -pointsize #{point_size}\
          -draw \"fill white text 0,#{h / 5} \'#{text}\'\"\
          \"#{tmpFile}\"")
        end
      Logger::info("Generating icons:")
      dimensions.each do |w|
        s = w.split(":")
        c = s[1].to_i
        sw = s[0].to_f * c
        dimension = "#{sw.to_i}x#{sw.to_i}"
        if c == 1
          file = "#{s[0]}.png"
        else
          file = "#{s[0]}@#{c}x.png"
        end
        Logger::log("  #{dimension} \e[90m▸\e[39m #{appiconsetDir}/#{file}")
        system("convert \"#{tmpFile}\" -resize #{dimension} \"#{appiconsetDir}/#{file}\"")
      end

       json_contents = JSON.pretty_generate(assetExport)
       FileUtils.rm(tmpFile)
       File.open("#{appiconsetDir}/Contents.json", 'w') { |file| file.write(json_contents) }
    end

    def write_asset(idiom, a, assetExport, dimensions)
      a[1].each do |l|
        c = "#{a[0]}:#{l}"
        if l == 1
          f = "#{a[0]}.png"
        else
          f = "#{a[0]}@#{l}x.png"
        end
        dic = {
          :size => "#{a[0]}x#{a[0]}",
          :idiom => idiom,
          :filename => f,
          :scale => "#{l}x"
        }
        if a.count == 3
          a[2].each do |key, value|
            dic[key] = value
          end
        end
        assetExport[:images] << dic
        if not dimensions.include? c
          dimensions << c
        end
      end
    end

    def error(message)
      Logger::error(message)

      abort
    end
  end
end
