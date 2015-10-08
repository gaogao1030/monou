require 'jekyll_asset_pipeline'
require 'coffee-script'
require 'sass'
#require 'yui/compressor'
require 'closure-compiler'
module JekyllAssetPipeline
  class CoffeeScriptConverter < JekyllAssetPipeline::Converter
    def self.filetype
      '.coffee'
    end

    def convert
      return CoffeeScript.compile(@content)
    end
  end
end


module JekyllAssetPipeline
  class SassConverter < JekyllAssetPipeline::Converter

    def self.filetype
      '.scss'
    end

    def convert
      return Sass::Engine.new(@content, syntax: :scss).render
    end
  end
end

module JekyllAssetPipeline
  class CssCompressor < JekyllAssetPipeline::Compressor
    def self.filetype
      '.css'
    end

    def compress
      return YUI::CssCompressor.new.compress(@content)
    end
  end

  #class JavaScriptCompressor < JekyllAssetPipeline::Compressor
  #  def self.filetype
  #    '.js'
  #  end

  #  def compress
  #    return YUI::JavaScriptCompressor.new(munge: true).compress(@content)
  #  end
  #end

  class JavaScriptCompressor < JekyllAssetPipeline::Compressor

    def self.filetype
      '.js'
    end

    def compress
      return Closure::Compiler.new.compile(@content)
    end
  end
end
