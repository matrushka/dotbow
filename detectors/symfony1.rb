module Symfony1Detector
  Bow.instance.detectors.push self
  def self.detect path
    return File.exists?("#{path}/symfony") && !`#{path}/symfony --version`.match(/Symfony(.)+ 1\./i).nil?
  end
end