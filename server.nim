import asynchttpserver
import asyncdispatch
import json
import strutils
import tables
import sugar

import chain
import exercise
import task

proc isImpl(req: Request, reqMethod: HttpMethod, path: string): bool =
    return req.reqMethod == reqMethod and req.url.path.startsWith(path)

proc isGet(req: Request, path: string): bool =
    return isImpl(req, HttpGet, path)

proc isPost(req: Request, path: string): bool =
    return isImpl(req, HttpPost, path)


proc executeAsync(Exercise: Exercise, stdin: string): Future[TaskChainStatus] =
    result = newFuture[TaskChainStatus]()
    try:
        result.complete(Exercise.execute(stdin=stdin))
    except Exception as e:
        result.fail(e)

proc back[T](items: seq[T]): T = items[items.len() - 1]

proc startServe*(port: uint16, Exercises: seq[Exercise]) =
    let indexedExercises = Exercises.toIndexed()

    proc version(req: Request) {.async.} =
        await req.respond(Http200, (%*{"system": "nim", "version": 1}).pretty())

    proc doExecute(req: Request) {.async.} =
        let preDefinedResponseHeaders = newHttpHeaders({"content-type": "application/json", "server": "ples.nim"})

        let path = req.url.path.toLower()
        let id = path.split('/').back()
        if not indexedExercises.hasKey(id):
            await req.respond(Http404, "not found")
            return
        let Exercise = indexedExercises[id]
        let status = await Exercise.executeAsync(req.body)

        let results = %*{
            "successfully": status.isSuccess(),
            "id": Exercise.id(), "name": Exercise.name(),
            "phase": status.phase(), "passed": status.passed()
        }
        let phases = newJArray()
        phases.elems = lc[%*{
                "code": s.statusCode(),
                "successfully": s.isSuccess(),
                "output": s.output()
            } | (s <- status.status()), JsonNode]
        results["phases"] = phases
        await req.respond(Http200, results.pretty(), preDefinedResponseHeaders)


    proc callback(req: Request){.async.} =
        echo req.protocol.orig, " ", req.reqMethod, " ", req.url.path
        try:
            if req.isGet("/"):
                await version(req)
                return
            if req.isPost("/v1/executor/"):
                await doExecute(req)
                return
        except:
            await req.respond(Http500, "internal server error")  # Internal Server Error
            return
        await req.respond(Http400, "bad request")  # Bad Request
        
    let server = newAsyncHttpServer()
    echo "Listening on http://localhost:" & $port
    waitFor server.serve(Port(port), callback)
