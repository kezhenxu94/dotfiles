return {
  {
    treesitter = { "java" },
    mason = { "jdtls", "java-debug-adapter", "java-test", "vscode-spring-boot-tools", "google-java-format" },
    lsp = { "jdtls" },
  },
  {
    treesitter = { "lua" },
    mason = { "stylua" },
    lsp = { "lua" },
  },
}
