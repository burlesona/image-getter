require 'roda'

$entries = {}
$counter = 0
Thread.new do
  while true do
    $counter += 1
    sleep 1
  end
end

class Crawler < Roda
  route do |r|
    r.root do
      "Counter says: #{$counter}"
    end
  end
end
