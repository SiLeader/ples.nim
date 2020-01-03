# ples.nim

&copy; 2020 SiLeader and Cerussite.

## License
Apache License 2.0

## test.json
```json
[
    {
        "id": "ex1",
        "name": "exercise",
        "pre": [
            "cp -r /ex1/* ."
        ],
        "tasks": [
            {
                "command": "tee",
                "arguments": ["a.hpp"],
                "statusOperator": "==",
                "statusRange": [0]
            },
            {
                "command": "clang++",
                "arguments": ["-o", "test", "valid.cpp"],
                "statusOperator": "==",
                "statusRange": [0]
            },
            {
                "command": "./test",
                "arguments": [],
                "statusOperator": "==",
                "statusRange": [0]
            },
            {
                "command": "clang++",
                "arguments": ["-o", "test", "invalid.cpp"],
                "statusOperator": "!=",
                "statusRange": [0]
            }
        ]
    }
]
```
