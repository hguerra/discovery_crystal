require "i18n"

I18n.config.loaders << I18n::Loader::YAML.new("config/locales")
I18n.config.default_locale = :en
I18n.init
