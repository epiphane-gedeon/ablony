module.exports = {
  env: {
    es6: true,
    node: true,
  },
  parserOptions: {
    // Le code utilise `?.` et `??`, arrivés en ES2020 : avec 2018, ESLint
    // n'arrivait même pas à analyser `index.js` et ne signalait donc plus
    // rien. Les fonctions tournent sur Node 22, qui comprend tout cela.
    "ecmaVersion": 2022,
  },
  extends: [
    "eslint:recommended",
    "google",
  ],
  rules: {
    "no-restricted-globals": ["error", "name", "length"],
    "prefer-arrow-callback": "error",
    "quotes": ["error", "double", {"allowTemplateLiterals": true}],
  },
  overrides: [
    {
      files: ["**/*.spec.*"],
      env: {
        mocha: true,
      },
      rules: {},
    },
  ],
  globals: {},
};
