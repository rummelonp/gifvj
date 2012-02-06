notification :growl

guard :less, output: 'app/stylesheets'do
  watch %r{app/less/.+\.less}
end

guard :coffeescript, bare: true, output: 'public/javascripts' do
  watch %r{app/coffeescript/.+\.coffee}
end

guard :livereload do
  watch %r{app/views/.+\.erb}
  watch %r{app/stylesheets/.+\.css}
  watch %r{public/javascripts/.+\.js}
end
