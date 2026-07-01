local qc = require("quickfix_command")

local mypy_output = [[
17:55:33.64 [INFO] Completed: Scheduling: Run MyPy on 21 files.
17:55:33.64 [ERROR] Completed: Typecheck using MyPy - (environment:local_fallback_docker_env, mypy) - mypy failed (exit code 1).
Partition #1 - default-pyspark-3-5, ['CPython<3.14,>=3.12']:
Success: no issues found in 1 source file

Partition #2 - iceberg-tables-operator, ['CPython==3.12.*']:
iceberg-tables-operator/src/iceberg_tables_operator/spec_diff_test.py:6: error: Function is missing a return type annotation  [no-untyped-def]
iceberg-tables-operator/src/iceberg_tables_operator/spec_diff_test.py:6: note: Use "-> None" if function does not return a value
iceberg-tables-operator/src/iceberg_tables_operator/spec_diff_test.py:8: error: Argument "transform" to "PartitionField" has incompatible type "str"; expected "Transform[Any, Any] | None"  [arg-type]
iceberg-tables-operator/src/iceberg_tables_operator/spec_diff_test.py:9: error: Argument "transform" to "PartitionField" has incompatible type "str"; expected "Transform[Any, Any] | None"  [arg-type]
Found 3 errors in 1 file (checked 21 source files)

Partition #3 - iceberg-tables-operator, ['CPython<3.14,>=3.12']:
Success: no issues found in 1 source file



✕ mypy failed.
]]

describe("quickfix_command", function()
    describe("parse_lines", function()
        it("parses mypy output into 4 quickfix items", function()
            local lines = vim.split(mypy_output, "\n", { trimempty = true })
            local items = qc.parse_lines(lines, { cwd = "/project" })

            assert.equals(4, #items)
        end)

        it("resolves filenames relative to cwd", function()
            local lines = vim.split(mypy_output, "\n", { trimempty = true })
            local items = qc.parse_lines(lines, { cwd = "/project" })

            for _, item in ipairs(items) do
                assert.truthy(item.filename:match("^/project/"))
            end
        end)

        it("maps error severity correctly", function()
            local lines = vim.split(mypy_output, "\n", { trimempty = true })
            local items = qc.parse_lines(lines, { cwd = "/project" })

            local errors = vim.tbl_filter(function(i) return i.type == "E" end, items)
            local notes  = vim.tbl_filter(function(i) return i.type == "I" end, items)

            assert.equals(3, #errors)
            assert.equals(1, #notes)
        end)

        it("captures correct line numbers", function()
            local lines = vim.split(mypy_output, "\n", { trimempty = true })
            local items = qc.parse_lines(lines, { cwd = "/project" })

            assert.equals(6, items[1].lnum)
            assert.equals(6, items[2].lnum)
            assert.equals(8, items[3].lnum)
            assert.equals(9, items[4].lnum)
        end)
    end)
end)
