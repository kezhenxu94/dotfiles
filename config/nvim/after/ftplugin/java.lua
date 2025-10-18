vim.g.java_ignore_markdown = true

local function get_mason_lombok_agent()
  return vim.fn.expand("$MASON/share/jdtls") .. "/lombok.jar"
end

vim.env.JDTLS_JVM_ARGS = "-javaagent:"
  .. get_mason_lombok_agent()
  .. " -XX:+UseParallelGC -XX:GCTimeRatio=4 -XX:AdaptiveSizePolicyWeight=90 -Xmx6G -Xms1G "
