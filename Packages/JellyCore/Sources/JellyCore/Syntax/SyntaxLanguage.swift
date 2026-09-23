public struct SyntaxLanguage: Sendable {
    public var lineComments: [String] = []
    public var blockComments: [(open: String, close: String)] = []
    public var strings: [String] = ["\"", "'"]
    public var multilineStrings: Set<String> = []
    public var keywords: Set<String> = []
    public var literals: Set<String> = []
    public var capitalizedTypes = true
    public var shellVariables = false
    public var tags = false
    public var diff = false

    public static func named(_ name: String) -> SyntaxLanguage? {
        let key = name.lowercased()
        return aliases[key].flatMap { languages[$0] } ?? languages[key]
    }

    private static let aliases: [String: String] = [
        "js": "javascript", "jsx": "javascript", "mjs": "javascript", "cjs": "javascript",
        "ts": "typescript", "tsx": "typescript", "mts": "typescript",
        "py": "python", "rb": "ruby", "rs": "rust", "golang": "go",
        "h": "c", "m": "c", "objc": "c", "objective-c": "c",
        "cc": "cpp", "cxx": "cpp", "hpp": "cpp", "hh": "cpp", "c++": "cpp", "mm": "cpp",
        "kt": "kotlin", "kts": "kotlin", "cs": "csharp", "c#": "csharp",
        "sh": "shell", "bash": "shell", "zsh": "shell", "console": "shell", "shellsession": "shell", "fish": "shell",
        "yml": "yaml", "htm": "html", "xml": "html", "svg": "html", "plist": "html", "vue": "html",
        "scss": "css", "less": "css", "patch": "diff", "jsonc": "json", "json5": "json",
        "dockerfile": "docker", "makefile": "make", "mk": "make", "ex": "elixir", "exs": "elixir",
        "zig": "zig", "lua": "lua", "php": "php", "psql": "sql",
    ]

    private static let cLikeLiterals: Set<String> = ["true", "false", "null", "nil", "undefined", "NULL", "nullptr", "None", "True", "False"]

    private static let jsKeywords: Set<String> = [
        "async", "await", "break", "case", "catch", "class", "const", "continue", "debugger", "default", "delete", "do",
        "else", "export", "extends", "finally", "for", "from", "function", "if", "import", "in", "instanceof", "let",
        "new", "of", "return", "static", "super", "switch", "this", "throw", "try", "typeof", "var", "void", "while",
        "with", "yield", "as", "get", "set",
    ]

    private static let languages: [String: SyntaxLanguage] = {
        var map: [String: SyntaxLanguage] = [:]
        map["swift"] = SyntaxLanguage(
            lineComments: ["//"], blockComments: [("/*", "*/")], strings: ["\"\"\"", "\""], multilineStrings: ["\"\"\""],
            keywords: [
                "actor", "any", "as", "associatedtype", "async", "await", "break", "case", "catch", "class", "continue",
                "default", "defer", "deinit", "do", "else", "enum", "extension", "fallthrough", "fileprivate", "final",
                "for", "func", "guard", "if", "import", "in", "init", "inout", "internal", "is", "lazy", "let", "mutating",
                "nonisolated", "open", "operator", "override", "private", "protocol", "public", "repeat", "rethrows",
                "return", "self", "Self", "some", "static", "struct", "subscript", "super", "switch", "throw", "throws",
                "try", "typealias", "var", "weak", "where", "while", "consuming", "borrowing", "package",
            ],
            literals: ["true", "false", "nil"]
        )
        map["javascript"] = SyntaxLanguage(
            lineComments: ["//"], blockComments: [("/*", "*/")], strings: ["\"", "'", "`"], multilineStrings: ["`"],
            keywords: jsKeywords, literals: cLikeLiterals
        )
        map["typescript"] = SyntaxLanguage(
            lineComments: ["//"], blockComments: [("/*", "*/")], strings: ["\"", "'", "`"], multilineStrings: ["`"],
            keywords: jsKeywords.union([
                "type", "interface", "enum", "implements", "namespace", "declare", "readonly", "private", "public",
                "protected", "abstract", "keyof", "satisfies", "infer", "is", "asserts", "any", "unknown", "never",
                "string", "number", "boolean",
            ]),
            literals: cLikeLiterals
        )
        map["python"] = SyntaxLanguage(
            lineComments: ["#"], strings: ["\"\"\"", "'''", "\"", "'"], multilineStrings: ["\"\"\"", "'''"],
            keywords: [
                "and", "as", "assert", "async", "await", "break", "class", "continue", "def", "del", "elif", "else",
                "except", "finally", "for", "from", "global", "if", "import", "in", "is", "lambda", "match", "case",
                "nonlocal", "not", "or", "pass", "raise", "return", "try", "while", "with", "yield", "self",
            ],
            literals: ["True", "False", "None"]
        )
        map["ruby"] = SyntaxLanguage(
            lineComments: ["#"], blockComments: [("=begin", "=end")],
            keywords: [
                "alias", "and", "begin", "break", "case", "class", "def", "defined?", "do", "else", "elsif", "end",
                "ensure", "for", "if", "in", "module", "next", "not", "or", "redo", "rescue", "retry", "return", "self",
                "super", "then", "undef", "unless", "until", "when", "while", "yield", "require", "attr_reader",
                "attr_accessor", "private",
            ],
            literals: ["true", "false", "nil"]
        )
        map["rust"] = SyntaxLanguage(
            lineComments: ["//"], blockComments: [("/*", "*/")], strings: ["\""],
            keywords: [
                "as", "async", "await", "break", "const", "continue", "crate", "dyn", "else", "enum", "extern", "fn",
                "for", "if", "impl", "in", "let", "loop", "match", "mod", "move", "mut", "pub", "ref", "return", "self",
                "Self", "static", "struct", "super", "trait", "type", "unsafe", "use", "where", "while",
            ],
            literals: ["true", "false", "None", "Some", "Ok", "Err"]
        )
        map["go"] = SyntaxLanguage(
            lineComments: ["//"], blockComments: [("/*", "*/")], strings: ["\"", "'", "`"], multilineStrings: ["`"],
            keywords: [
                "break", "case", "chan", "const", "continue", "default", "defer", "else", "fallthrough", "for", "func",
                "go", "goto", "if", "import", "interface", "map", "package", "range", "return", "select", "struct",
                "switch", "type", "var",
            ],
            literals: ["true", "false", "nil", "iota"]
        )
        let cKeywords: Set<String> = [
            "auto", "break", "case", "char", "const", "continue", "default", "do", "double", "else", "enum", "extern",
            "float", "for", "goto", "if", "inline", "int", "long", "register", "return", "short", "signed", "sizeof",
            "static", "struct", "switch", "typedef", "union", "unsigned", "void", "volatile", "while", "#include",
            "#define", "#import", "#if", "#ifdef", "#ifndef", "#endif", "#else", "#pragma", "@interface",
            "@implementation", "@end", "@property", "self",
        ]
        map["c"] = SyntaxLanguage(lineComments: ["//"], blockComments: [("/*", "*/")], keywords: cKeywords, literals: cLikeLiterals)
        map["cpp"] = SyntaxLanguage(
            lineComments: ["//"], blockComments: [("/*", "*/")],
            keywords: cKeywords.union([
                "class", "namespace", "template", "typename", "public", "private", "protected", "virtual", "override",
                "new", "delete", "this", "using", "auto", "constexpr", "noexcept", "try", "catch", "throw", "bool",
            ]),
            literals: cLikeLiterals
        )
        let jvmKeywords: Set<String> = [
            "abstract", "break", "case", "catch", "class", "continue", "default", "do", "else", "enum", "extends",
            "final", "finally", "for", "if", "implements", "import", "interface", "new", "package", "private",
            "protected", "public", "return", "static", "super", "switch", "this", "throw", "throws", "try", "void",
            "while", "var", "val", "fun", "object", "when", "is", "in", "override", "data", "sealed", "suspend",
            "int", "boolean", "long", "double", "float", "char", "byte", "short",
        ]
        map["java"] = SyntaxLanguage(lineComments: ["//"], blockComments: [("/*", "*/")], keywords: jvmKeywords, literals: cLikeLiterals)
        map["kotlin"] = map["java"]
        map["csharp"] = SyntaxLanguage(
            lineComments: ["//"], blockComments: [("/*", "*/")],
            keywords: jvmKeywords.union(["namespace", "using", "async", "await", "string", "bool", "readonly", "record", "get", "set"]),
            literals: cLikeLiterals
        )
        map["shell"] = SyntaxLanguage(
            lineComments: ["#"], multilineStrings: ["\"", "'"],
            keywords: [
                "if", "then", "else", "elif", "fi", "for", "while", "until", "do", "done", "case", "esac", "in",
                "function", "return", "local", "export", "set", "unset", "source", "alias", "echo", "cd", "exit",
                "end", "begin", "and", "or", "not", "sudo",
            ],
            literals: ["true", "false"], capitalizedTypes: false, shellVariables: true
        )
        map["docker"] = SyntaxLanguage(
            lineComments: ["#"],
            keywords: ["FROM", "RUN", "CMD", "COPY", "ADD", "ENV", "ARG", "WORKDIR", "EXPOSE", "ENTRYPOINT", "USER", "VOLUME", "LABEL", "AS"],
            capitalizedTypes: false, shellVariables: true
        )
        map["make"] = SyntaxLanguage(lineComments: ["#"], keywords: ["ifeq", "ifneq", "ifdef", "ifndef", "else", "endif", "include", "define", "endef"], capitalizedTypes: false, shellVariables: true)
        map["json"] = SyntaxLanguage(lineComments: ["//"], strings: ["\""], literals: ["true", "false", "null"], capitalizedTypes: false)
        map["toml"] = SyntaxLanguage(
            lineComments: ["#"], strings: ["\"\"\"", "'''", "\"", "'"], multilineStrings: ["\"\"\"", "'''"],
            literals: ["true", "false"], capitalizedTypes: false
        )
        map["yaml"] = SyntaxLanguage(lineComments: ["#"], literals: ["true", "false", "null", "yes", "no", "on", "off"], capitalizedTypes: false)
        map["html"] = SyntaxLanguage(blockComments: [("<!--", "-->")], strings: ["\""], capitalizedTypes: false, tags: true)
        map["css"] = SyntaxLanguage(
            blockComments: [("/*", "*/")],
            keywords: ["@media", "@import", "@keyframes", "@font-face", "@supports", "!important"],
            capitalizedTypes: false
        )
        map["sql"] = SyntaxLanguage(
            lineComments: ["--"], blockComments: [("/*", "*/")], strings: ["'", "\""],
            keywords: Set([
                "select", "from", "where", "insert", "into", "values", "update", "set", "delete", "create", "table",
                "alter", "drop", "index", "join", "left", "right", "inner", "outer", "on", "and", "or", "not", "as",
                "group", "by", "order", "limit", "offset", "having", "primary", "key", "references", "default",
                "returning", "with", "union", "distinct", "case", "when", "then", "else", "end", "is", "in", "exists",
            ].flatMap { [$0, $0.uppercased()] }),
            literals: ["null", "NULL", "true", "false", "TRUE", "FALSE"],
            capitalizedTypes: false
        )
        map["lua"] = SyntaxLanguage(
            lineComments: ["--"], blockComments: [("--[[", "]]")],
            keywords: ["and", "break", "do", "else", "elseif", "end", "for", "function", "goto", "if", "in", "local", "not", "or", "repeat", "return", "then", "until", "while"],
            literals: ["true", "false", "nil"]
        )
        map["php"] = SyntaxLanguage(
            lineComments: ["//", "#"], blockComments: [("/*", "*/")],
            keywords: jsKeywords.union(["echo", "public", "private", "protected", "namespace", "use", "fn", "foreach", "elseif", "endif"]),
            literals: cLikeLiterals, shellVariables: true
        )
        map["elixir"] = SyntaxLanguage(
            lineComments: ["#"], strings: ["\"\"\"", "\""], multilineStrings: ["\"\"\""],
            keywords: ["def", "defp", "defmodule", "do", "end", "fn", "case", "cond", "with", "if", "else", "unless", "import", "alias", "use", "require", "when"],
            literals: ["true", "false", "nil"]
        )
        map["zig"] = SyntaxLanguage(
            lineComments: ["//"], strings: ["\""],
            keywords: ["const", "var", "fn", "pub", "return", "if", "else", "while", "for", "switch", "struct", "enum", "union", "try", "catch", "defer", "errdefer", "comptime", "test"],
            literals: ["true", "false", "null", "undefined"]
        )
        map["diff"] = SyntaxLanguage(strings: [], capitalizedTypes: false, diff: true)
        return map
    }()
}
