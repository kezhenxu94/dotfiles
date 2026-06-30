vim.g.java_ignore_markdown = true

-- lombok.jar is installed by packages/install/packages/84-lsp-bin.sh.
vim.env.JDTLS_JVM_ARGS = "-javaagent:"
  .. vim.fn.expand("~/usr/local/jdtls/lombok.jar")
  .. " -XX:+UseParallelGC -XX:GCTimeRatio=4 -XX:AdaptiveSizePolicyWeight=90 -Xmx6G -Xms1G "
