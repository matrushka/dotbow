module Symfony2Detector
  Bow.instance.detectors.push self
  def self.detect path
    return File.exists?("#{path}/app/console") && !`#{path}/app/console --version`.match(/Symfony(.)+ 2\./i).nil?
  end
end