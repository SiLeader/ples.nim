import json

import exercise
import server

let jsonData = "exercises.json".readFile()
let jo = parseJson(jsonData)

let exercises = createExercisesFromJsonObject(jo)

startServe(8080, exercises)
