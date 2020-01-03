import chain
import json
import sugar
import tables
import random
import os
import sequtils
import osproc


type ExerciseObj = object of RootObj
    id: string
    name: string
    chain: TaskChain
    pre: seq[string]
type Exercise* = ref ExerciseObj


randomize()


proc createExerciseFromJsonObject(jsonObject: JsonNode): Exercise =
    result = Exercise()
    result.id = jsonObject["id"].getStr()
    result.name = jsonObject["name"].getStr()
    result.chain = createChainFromJsonObject(jsonObject)
    result.pre = jsonObject["pre"].elems.map(x => x.getStr())


proc createExercisesFromJsonObject*(jsonObject: JsonNode): seq[Exercise] =
    return lc[createExerciseFromJsonObject(jo) | (jo <- jsonObject.items), Exercise]


proc toIndexed*(ex: seq[Exercise]): Table[string, Exercise] =
    result = initTable[string, Exercise]()
    for e in ex:
        result[e.id] = e


proc id*(self: Exercise): string =
    return self.id

proc name*(self: Exercise): string =
    return self.name

proc chain*(self: Exercise): TaskChain =
    return self.chain


proc randomString(length: int): string =
    const str = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    for _ in countup(1, length):
        result &= sample(str)

proc execute*(self: Exercise, workingDirectory: string="", stdin: string="", abortIfFail: bool = true): TaskChainStatus =
    var wd = workingDirectory
    if workingDirectory.len() == 0:
        wd = "/tmp/ples.nim-" & randomString(64)
        createDir(wd)
    for command in self.pre:
        discard execProcess(command, workingDir=wd)
    result = self.chain.execute(stdin=stdin, workingDirectory=wd, abortIfFail=abortIfFail)
    if wd != workingDirectory:
        removeDir(wd)
