// Conventional Commits, as documented in CONTRIBUTING.md.
//
// @commitlint/config-conventional was already a devDependency but no config
// file existed, so `commitlint --edit` failed with "no configuration found"
// — the commit-msg hook could never have passed even once husky was working.
module.exports = {
  extends: ['@commitlint/config-conventional'],
  rules: {
    // The scopes this repo actually uses, so a typo like `fix(notification)`
    // is caught rather than silently accepted.
    'scope-enum': [
      1, // warn, not error — a new feature should not be blocked by this list
      'always',
      [
        'a11y',
        'android',
        'azkar',
        'backup',
        'ci',
        'deps',
        'design',
        'docs',
        'fasting',
        'floating-dhikr',
        'home',
        'ios',
        'notifications',
        'onboarding',
        'prayer-times',
        'quran',
        'radio',
        'release',
        'salah',
        'settings',
        'share',
        'test',
        'tasbih',
        'widgets',
        'wird',
        'zakat',
      ],
    ],
    // Arabic copy in a subject line pushes past 72 characters easily.
    'header-max-length': [2, 'always', 100],
  },
};
