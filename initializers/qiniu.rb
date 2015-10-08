QINIU_CONFIG = YAML.load_file("qiniu.yml")
Qiniu.establish_connection! :access_key => QINIU_CONFIG["access_key"], :secret_key => QINIU_CONFIG["secret_key"]

module Qiniu
  class << self
    def list(opt={})
      opt[:bucket]||= QINIU_CONFIG["bucket"]
      opt[:limit] ||= 1000
      opt[:prefix]||=""
      opt[:delimiter]||=""
      policy = Qiniu::Storage::ListPolicy.new(opt[:bucket],opt[:limit],opt[:prefix],opt[:delimiter])
      return Qiniu::Storage.list(policy)
    end
  end
end

