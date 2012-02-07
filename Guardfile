notification :growl

guard :less, output: 'public/stylesheets'do
  watch %r{app/less/.+\.less}
end

guard :coffeescript, output: 'public/javascripts', bare: true do
  watch %r{app/coffeescript/.+\.coffee}
end

guard :livereload do
  watch %r{app/views/.+\.erb}
  watch %r{app/stylesheets/.+\.css}
  watch %r{public/javascripts/.+\.js}
end
