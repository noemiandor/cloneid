import { cellLineOrLineageId, descendants, validateCellId, validateCellLine } from "$lib/js/query/funcs.js";
import { fetchStmtRows } from '$lib/mysql/fetchFromProxy';
import { spawn } from "node:child_process";
import { writeFileSync } from 'node:fs';

async function generateRScriptForHeatmap(dataMatrix, outputFile, scriptargs) {

    const scriptContent = `
# R Script for Heatmap
library(gplots)

# Your heatmap data
#dataMatrix <- ${JSON.stringify(dataMatrix)}

# Set up color palette and labels
#colors <- colorRampPalette(c("blue", "white", "red"))(100)
#rownames(dataMatrix) <- 1:nrow(dataMatrix)
#colnames(dataMatrix) <- 1:ncol(dataMatrix)

# Create heatmap
#heatmap.2(dataMatrix, col = colors, key = TRUE, keysize = 1.5, trace = "none", margins = c(8, 10), cexRow = 1.0, cexCol = 1.0)

# Save the heatmap plot to a file
png('${scriptargs[0]}', width = 800, height = 600)
#heatmap.2(dataMatrix, col = colors, key = TRUE, keysize = 1.5, trace = "none", margins = c(8, 10), cexRow = 1.0, cexCol = 1.0)
heatmap.2(t(cars), trace = "none");
dev.off()
`;

    writeFileSync(outputFile, scriptContent);

    const ls = spawn('Rscript', [outputFile]);
    ls.stdout
    ls.stdout.on('data', (data) => {
        console.log(`stdout: ${data}`);
    });
    ls.stderr.on('data', (data) => {
        console.log(`stderr: ${data}`);
    });


    return ls.exitCode;
}

async function originWithPerspective() {

    const stmt =
   `SELECT distinct origin, whichPerspective
    FROM Perspective t1
    JOIN Passaging t2 ON t1.origin = t2.id
    UNION
    SELECT distinct t2.passaged_from_id1 passage, whichPerspective
    FROM Perspective t1
    JOIN Passaging t2 ON t1.origin = t2.id
    WHERE (t2.passaged_from_id1 IS NOT NULL) AND NOT EXISTS (SELECT  distinct origin FROM Perspective t1 where origin=t2.passaged_from_id1);`;


    const withP = await fetchStmtRows(stmt)
        .then((x) => {
            if (x) {
                return x;
            } else {
                return [];
            }
        })
        .catch((e) => {
            console.log("ERROR", e);
        });
    return withP;
}

async function sampleSourceMorphologyperspective(sampleSource) {
    const stmt = `SELECT origin, whichPerspective from MorphologyPerspective where parent IS NULL AND hasChildren=true AND sampleSource='${sampleSource}' AND whichPerspective='MorphologyPerspective' ORDER BY size DESC;`;
    const withM = await fetchStmtRows(stmt)
        .then((x) => {
            if (x) {
                return x;
            } else {
                return [];
            }
        })
        .catch((e) => {
            console.log("ERROR", e);
        });
    return withM;
}

/** @type {import('./$types').Actions} */
export const actions = {
    morphologyperspective: async ({ request }) => {
        const formdata = await request.formData();
        const sampleSource = formdata.get("samplesource")?.valueOf();
        return ({
            morphologyperspective: JSON.stringify(await sampleSourceMorphologyperspective(sampleSource))
        });
    },

    perspectives: async ({ request }) => {
        return {
            perspectives: JSON.stringify(await originWithPerspective())
        };
    },

    getdescendants: async ({ request }) => {
        const formdata = await request.formData();
        const item = formdata.get("item")?.valueOf();
        const val = item;
        const type = "validatecellorid";
        let result = { query: "validatecellorid", date: new Date(), CellLine: null, CellId: null, result: [] };
        if (val) {
            await validateCellLine(val)
                .then((rows) => {
                    const count = rows.length;
                    if (count > 0) {
                        const row = rows[0];
                        let validCellLine =
                            (row['id'] && row['cellLine'] && row['id'] === row['cellLine']);
                        if (validCellLine !== true) {
                            validCellLine = false;
                        }
                        result.CellLine = validCellLine;
                    }
                })
                .catch((e) => {
                    console.log("HOMEPAGE::BASE::VALIDATECELLLINE::ERROR::", type, val, result);
                    throw e;
                })
                ;
            await validateCellId(val)
                .then((rows) => {
                    const count = rows.length;
                    if (count > 0) {
                        const row = rows[0];
                        let validCellId =
                            (row['id'] && row['cellLine'] && row['id'] != row['cellLine']);
                        if (validCellId != true) {
                            validCellId = false;
                        }
                        result.CellId = validCellId;
                    }
                })
                .catch((e) => {
                    console.log("HOMEPAGE::BASE::VALIDATECELLID::ERROR::", type, val, result);
                    throw e;
                })
                ;
        }

        const cellOrId = result;
        if (cellOrId['CellLine'] === true && cellOrId['CellId'] === false) {
            await cellLineOrLineageId(item)
                .then(async (pedigreeTree) => {
                    result.result = pedigreeTree;
                })
                .catch((e) => {
                    throw e;
                });
        } else if (cellOrId['CellLine'] === false && cellOrId['CellId'] === true) {
            await descendants([item])
                .then(async (pedigreeTree) => {
                    result.result = pedigreeTree;
                })
                .catch((e) => {
                    throw e;
                });
        }

        return {
            result: JSON.stringify(result.result)
        };
    },

    getpedigreetree: async ({ request }) => {
        const formdata = await request.formData();
        const item = formdata.get("item")?.valueOf();
        const val = item;
        const type = "validatecellorid";
        let result = { 'query': "validatecellorid", 'date': new Date(), CellLine: null, CellId: null, tree: null };
        if (val) {
            await validateCellLine(val)
                .then((rows) => {
                    const count = rows.length;
                    if (count > 0) {
                        const row = rows[0];
                        let validCellLine =
                            (row['id'] && row['cellLine'] && row['id'] === row['cellLine']);
                        if (validCellLine !== true) {
                            validCellLine = false;
                        }
                        result.CellLine = validCellLine;
                    }
                })
                .catch((e) => {
                    console.log("HOMEPAGE::BASE::VALIDATECELLLINE::ERROR::", type, val, result);
                    throw e;
                })
                ;
            await validateCellId(val)
                .then((rows) => {
                    const count = rows.length;
                    if (count > 0) {
                        const row = rows[0];
                        let validCellId =
                            (row['id'] && row['cellLine'] && row['id'] != row['cellLine']);
                        if (validCellId != true) {
                            validCellId = false;
                        }
                        result.CellId = validCellId;
                    }
                })
                .catch((e) => {
                    console.log("HOMEPAGE::BASE::VALIDATECELLID::ERROR::", type, val, result);
                    throw e;
                })
                ;
        }

        const cellOrId = result;
        if (cellOrId['CellLine'] === true && cellOrId['CellId'] === false) {
            await cellLineOrLineageId(item)
                .then(async (pedigreeTree) => {
                    result.tree = pedigreeTree;
                })
                .catch((e) => {
                    throw e;
                });
        } else if (cellOrId['CellLine'] === false && cellOrId['CellId'] === true) {
            await descendants([item])
                .then(async (pedigreeTree) => {
                    result.tree = pedigreeTree;
                })
                .catch((e) => {
                    throw e;
                });
        } else {
            throw cellOrId;
        }

        return {
            tree: JSON.stringify(result.tree)
        };
    },

    callbackendscriptgen: async ({ request }) => {
        const formdata = await request.formData();
        const item = formdata.get("item")?.valueOf();
        const val = JSON.parse(item);
        let result = { 'query': "callbackendscriptgen", 'date': new Date(), CellLine: null, CellId: null, result: val };

        const xx = await generateRScriptForHeatmap(val, "hscript.R", ["hscript.png"]);

        return {
            result: JSON.stringify(result)
        };
    },
}
