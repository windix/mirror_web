# I18n.available_locales

LANGUAGES = {
  'English' => 'en',
  '简体中文' => 'zh-CN',
  '繁體中文' => 'zh-TW',
}

fb = I18n.fallbacks
fb.map :"zh-HK" => :"zh-TW"
fb.map :"zh-SG" => :"zh-CN"
