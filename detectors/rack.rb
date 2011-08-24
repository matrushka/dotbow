module RackDetector
  Bow.instance.detectors.push self
  def self.detect path
    return File.exists?("#{path}/config.ru") && File.directory?("#{path}/public") && File.directory?("#{path}/tmp")
  end
end