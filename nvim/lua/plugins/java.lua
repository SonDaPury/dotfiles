-- Cấu hình Java LSP (nvim-jdtls) & Java Tooling
-- Dùng nvim-jdtls thay cho lspconfig mặc định vì Eclipse JDTLS cần workspace cache riêng,
-- hỗ trợ nạp Lombok agent, tích hợp DAP Java (Tomcat / Docker remote debug) và các tính năng refactor.

return {
  {
    "mfussenegger/nvim-jdtls",
    ft = { "java" },
    dependencies = {
      "mfussenegger/nvim-dap",
      "mason-org/mason.nvim",
      "saghen/blink.cmp",
    },
    config = function()
      -- Tự động kiểm tra và cài đặt jdtls + google-java-format qua Mason nếu chưa có
      local has_mason, mr = pcall(require, "mason-registry")
      if has_mason then
        for _, pkg_name in ipairs({ "jdtls", "google-java-format" }) do
          if mr.has_package(pkg_name) then
            local pkg = mr.get_package(pkg_name)
            if not pkg:is_installed() then
              pkg:install()
            end
          end
        end
      end

      local function start_jdtls()
        local jdtls = require("jdtls")
        local mason_path = vim.fn.stdpath("data") .. "/mason"

        -- 1. Tìm đường dẫn binary jdtls (ưu tiên binary do Mason cài đặt)
        local jdtls_bin = mason_path .. "/bin/jdtls"
        if vim.fn.executable(jdtls_bin) ~= 1 then
          jdtls_bin = vim.fn.exepath("jdtls")
        end

        -- Nếu jdtls chưa có sẵn (ví dụ chưa cài xong hoặc chưa có Java trên host để chạy),
        -- ghi nhận và bỏ qua an toàn để tránh treo Neovim.
        if not jdtls_bin or jdtls_bin == "" then
          return
        end

        -- 2. Xác định root thư mục dự án Java (dựa vào Maven pom.xml, Gradle hoặc .git)
        local root_markers = { ".git", "mvnw", "gradlew", "pom.xml", "build.gradle", "build.gradle.kts" }
        local root_dir = require("jdtls.setup").find_root(root_markers)
        if not root_dir then
          root_dir = vim.fs.dirname(vim.fs.find(root_markers, { upward = true })[1])
            or vim.fn.expand("%:p:h")
        end

        -- Tên thư mục dự án và workspace cache riêng biệt cho JDTLS
        local project_name = vim.fs.basename(root_dir) or "default"
        local workspace_dir = vim.fn.stdpath("cache") .. "/jdtls/workspace/" .. project_name

        -- 3. Tạo cmd khởi động JDTLS
        local cmd = { jdtls_bin, "-data", workspace_dir }

        -- Tự động thêm Lombok agent nếu có sẵn file lombok.jar trong thư mục Mason jdtls
        local lombok_path = mason_path .. "/packages/jdtls/lombok.jar"
        if vim.uv.fs_stat(lombok_path) then
          table.insert(cmd, string.format("--jvm-arg=-javaagent:%s", lombok_path))
        end

        -- 4. Thu thập bundles DAP (java-debug-adapter và java-test)
        local bundles = {}
        local java_dbg_pattern = mason_path .. "/packages/java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar"
        local java_dbg_bundles = vim.fn.glob(java_dbg_pattern, true, true)
        if #java_dbg_bundles > 0 then
          vim.list_extend(bundles, java_dbg_bundles)
        end

        local java_test_pattern = mason_path .. "/packages/java-test/extension/server/*.jar"
        local java_test_bundles = vim.fn.glob(java_test_pattern, true, true)
        if #java_test_bundles > 0 then
          vim.list_extend(bundles, java_test_bundles)
        end

        -- 5. Lấy capabilities từ blink.cmp
        local capabilities = vim.lsp.protocol.make_client_capabilities()
        local has_blink, blink = pcall(require, "blink.cmp")
        if has_blink then
          capabilities = blink.get_lsp_capabilities(capabilities)
        end

        -- 6. Cấu hình chi tiết cho Eclipse JDTLS
        local settings = {
          java = {
            signatureHelp = { enabled = true },
            contentProvider = { preferred = "fernflower" },
            completion = {
              favoriteStaticMembers = {
                "org.junit.Assert.*",
                "org.junit.Assume.*",
                "org.junit.jupiter.api.Assertions.*",
                "org.junit.jupiter.api.Assumptions.*",
                "org.mockito.Mockito.*",
              },
              importOrder = {
                "java",
                "javax",
                "jakarta",
                "com",
                "org",
              },
            },
            sources = {
              organizeImports = {
                starThreshold = 9999,
                staticStarThreshold = 9999,
              },
            },
            codeGeneration = {
              toString = {
                template = "${object.className}{${member.name()}=${member.value}, ${otherMembers}}",
              },
              useBlocks = true,
            },
            configuration = {
              updateBuildConfiguration = "interactive",
            },
            referencesCodeLens = { enabled = true },
            implementationsCodeLens = { enabled = true },
          },
        }

        local config = {
          cmd = cmd,
          root_dir = root_dir,
          settings = settings,
          capabilities = capabilities,
          init_options = {
            bundles = bundles,
            extendedClientCapabilities = jdtls.extendedClientCapabilities,
          },
          on_attach = function(client, bufnr)
            -- Đăng ký DAP debugger cho Java
            pcall(function()
              jdtls.setup_dap({ hotcodereplace = "auto" })
              require("jdtls.dap").setup_dap_main_class_configs()
            end)

            -- Keymaps chuyên biệt cho Java (prefix <leader>j)
            local map = vim.keymap.set
            local opts = { buffer = bufnr }

            map("n", "<leader>jo", function() jdtls.organize_imports() end, vim.tbl_extend("force", opts, { desc = "Java: Organize Imports" }))
            map("n", "<leader>jv", function() jdtls.extract_variable() end, vim.tbl_extend("force", opts, { desc = "Java: Extract Variable" }))
            map("v", "<leader>jv", function() jdtls.extract_variable(true) end, vim.tbl_extend("force", opts, { desc = "Java: Extract Variable" }))
            map("n", "<leader>jc", function() jdtls.extract_constant() end, vim.tbl_extend("force", opts, { desc = "Java: Extract Constant" }))
            map("v", "<leader>jc", function() jdtls.extract_constant(true) end, vim.tbl_extend("force", opts, { desc = "Java: Extract Constant" }))
            map("v", "<leader>jm", function() jdtls.extract_method(true) end, vim.tbl_extend("force", opts, { desc = "Java: Extract Method" }))
            map("n", "<leader>jt", function() jdtls.test_nearest_method() end, vim.tbl_extend("force", opts, { desc = "Java: Test Nearest Method" }))
            map("n", "<leader>jT", function() jdtls.test_class() end, vim.tbl_extend("force", opts, { desc = "Java: Test Class" }))
            map("n", "<leader>ju", function() jdtls.update_project_config() end, vim.tbl_extend("force", opts, { desc = "Java: Update Project Config" }))
          end,
        }

        -- Khởi động hoặc attach client JDTLS vào buffer
        jdtls.start_or_attach(config)
      end

      -- Autocmd kích hoạt mỗi khi mở file Java
      local java_augroup = vim.api.nvim_create_augroup("java-jdtls", { clear = true })
      vim.api.nvim_create_autocmd("FileType", {
        group = java_augroup,
        pattern = "java",
        callback = start_jdtls,
      })

      -- Nếu buffer hiện tại đã là file Java khi config() được gọi, thực thi ngay
      if vim.bo.filetype == "java" then
        start_jdtls()
      end
    end,
  },
}
