export function drawPedigreeTree() {

    var trees = [];
    var renderedTrees = [];
    var longestNode = {};

    var compareMode = false;

    var maxBranchSupport = 0
    var maxLength = 0
    var triangleType = "triangle-down";

    var colorScaleRange = ['rgb(37,52,148)', 'rgb(44,127,184)', 'rgb(65,182,196)', 'rgb(127,205,187)', 'rgb(199,233,180)', 'rgb(255,255,204)'];
    var colorScaleRangeRest = ['rgb(179,0,0)', 'rgb(227,74,51)', 'rgb(252,141,89)', 'rgb(253,187,132)', 'rgb(253,212,158)', 'rgb(254,240,217)'];
    var colorScaleDomain = [1, 0.8, 0.6, 0.4, 0.2, 0];

    const perspectiveLabelColor = {
        GenomePerspective: "#4a58dd",
        ExomePerspective: "#27d7c4",
        TranscriptomePerspective: "#95fb51",
        KaryotypePerspective: "#ffa423",
        MorphologyPerspective: "#ba2208",
    }
    const perspectiveLabelColor1 = {
        GenomePerspective: 'rgb(74,88,221',
        ExomePerspective: 'rgb(39,215,196)',
        TranscriptomePerspective: 'rgb(149,251,81)',
        KaryotypePerspective: 'rgb(255,164,35)',
        MorphologyPerspective: 'rgb(186,34,8)',
    }


    var paddingVertical = 0;

    var triangleHeightDivisor = 40;
    var currentS = "elementS";

    var settings = {
        gistSaveServerURL: "",
        useLengths: true,
        alignTipLables: false,
        selectMultipleSearch: false,
        fontSize: 14,
        lineThickness: 1,
        nodeSize: 5,
        treeWidth: 10,
        treeHeight: 19,
        moveOnClick: true,
        enableZoomSliders: true,
        scaleMin: 0.01,
        scaleMax: 2,
        scaleColor: "black",
        loadingCallback: function () { },
        loadedCallback: function () { },
        internalLabels: "name",
        enableDownloadButtons: false,
        enableCloudShare: false,
        enableLadderizeTreeButton: false,
        enableOppositeTreeActions: false,
        enableFisheyeZoom: false,
        enableScale: true,
        zoomMode: "traditional",
        fitTree: "scale",
        enableSizeControls: false,
        enableSearch: false,
        autoCollapse: null,
        callbackA: function (x) { },
        callbackB: function () { },
        callbackC: function (/** @type {any} */ x) { },
        callbackD: function () { return 1.0; },
        callbackE: function () { return {}; },
        callbackF: function (x, s) { },
        callbackG: function (/** @type {any} */ x) { return []; },
        callbackH: function (/** @type {any} */ x) { return true; },
        callbackI: function (/** @type {any} */ x) { return true; },
        callbackJ: function (/** @type {any} */ x) { return true; },
        callbackK: function (/** @type {any} */ x) { return true; },
        callbackL: function (/** @type {any} */ x, /** @type {any} */ y) { },
        callbackM: function (/** @type {any} */ x) { return true; },
        callbackN: function (/** @type {any} */ x) { return []; },
        callbackO: function (/** @type {any} */ x) { return []; },
    };

    $.work = function (args) {
        var def = $.Deferred(function (dfd) {
            var worker;
            if (window.Worker) {
                worker = new Worker(args.file);
                worker.onmessage = function (event) {
                    dfd.resolve(event.data);
                };
                worker.onerror = function (event) {
                    dfd.reject(event);
                };
                worker.postMessage(args.args);
            }
        });
        return def.promise();
    };

    function init(settingsIn) {
        var mySettings = settingsIn ? settingsIn : {};
        changeTreeSettings(mySettings);
        return this;
    }

    function getSetting(currentSetting, lastSetting) {
        if (currentSetting !== undefined) {
            return currentSetting;
        } else {
            return lastSetting;
        }
    }

    function changeTreeSettings(settingsIn) {
        settings.useLengths = getSetting(settingsIn.useLengths, settings.useLengths);
        settings.alignTipLabels = getSetting(settingsIn.alignTipLabels, settings.alignTipLabels);
        settings.mirrorRightTree = getSetting(settingsIn.mirrorRightTree, settings.mirrorRightTree);
        settings.selectMultipleSearch = getSetting(settingsIn.selectMultipleSearch, settings.selectMultipleSearch);
        settings.fontSize = getSetting(settingsIn.fontSize, settings.fontSize);
        settings.lineThickness = getSetting(settingsIn.lineThickness, settings.lineThickness);
        settings.nodeSize = getSetting(settingsIn.nodeSize, settings.nodeSize);
        settings.treeWidth = getSetting(settingsIn.treeWidth, settings.treeWidth);
        settings.treeHeight = getSetting(settingsIn.treeHeight, settings.treeHeight);
        settings.moveOnClick = getSetting(settingsIn.moveOnClick, settings.moveOnClick);
        settings.scaleMin = getSetting(settingsIn.scaleMin, settings.scaleMin);
        settings.scaleMax = getSetting(settingsIn.scaleMax, settings.scaleMax);
        settings.scaleColor = getSetting(settingsIn.scaleColor, settings.scaleColor);
        settings.loadingCallback = getSetting(settingsIn.loadingCallback, settings.loadingCallback);
        settings.loadedCallback = getSetting(settingsIn.loadedCallback, settings.loadedCallback);
        settings.internalLabels = getSetting(settingsIn.internalLabels, settings.internalLabels);
        settings.zoomMode = getSetting(settingsIn.zoomMode, settings.zoomMode);
        settings.fitTree = getSetting(settingsIn.fitTree, settings.fitTree);
        settings.gistSaveServerURL = getSetting(settingsIn.gistSaveServerURL, settings.gistSaveServerURL);
        settings.callbackA = getSetting(settingsIn.callbackA, settings.callbackA);
        settings.callbackB = getSetting(settingsIn.callbackB, settings.callbackB);
        settings.callbackC = getSetting(settingsIn.callbackC, settings.callbackC);
        settings.callbackD = getSetting(settingsIn.callbackD, settings.callbackD);
        settings.callbackE = getSetting(settingsIn.callbackE, settings.callbackE);
        settings.callbackF = getSetting(settingsIn.callbackF, settings.callbackF);
        settings.callbackG = getSetting(settingsIn.callbackG, settings.callbackG);
        settings.callbackH = getSetting(settingsIn.callbackH, settings.callbackH);
        settings.callbackI = getSetting(settingsIn.callbackI, settings.callbackI);
        settings.callbackJ = getSetting(settingsIn.callbackJ, settings.callbackJ);
        settings.callbackK = getSetting(settingsIn.callbackK, settings.callbackK);
        settings.callbackL = getSetting(settingsIn.callbackL, settings.callbackL);
        settings.callbackM = getSetting(settingsIn.callbackM, settings.callbackM);
        settings.callbackN = getSetting(settingsIn.callbackN, settings.callbackN);
        settings.callbackO = getSetting(settingsIn.callbackO, settings.callbackO);

        var i;
        if (!(settingsIn.treeWidth === undefined)) {
            for (i = 0; i < trees.length; i++) {
                jQuery.extend(trees[i].data, {
                    treeWidth: settingsIn.treeWidth
                });
            }
        }
        if (!(settingsIn.treeHeight === undefined)) {
            for (i = 0; i < trees.length; i++) {
                jQuery.extend(trees[i].data, {
                    treeHeight: settingsIn.treeHeight
                });
            }
        }
        updateAllRenderedTrees();
    }

    /**
     * @type {{ [x: string]: any; } | null}
     */
    var capabilities = null;
    /**
         * @param {string} cap
         */
    function capableOf(cap) {
        if (capabilities == null) {
            capabilities = settings.callbackE();
        }
        let ret = false;
        if (cap in capabilities) {
            ret = capabilities[cap];
        } else {
            ret = false;
        }
        return ret;
    }

    function updateAllRenderedTrees() {
        for (var i = 0; i < renderedTrees.length; i++) {
            update(renderedTrees[i].data.root, renderedTrees[i].data);
        }
    }
    function checkTreeInput(s) {
        var tokens = s.split(/\s*(;|\(|\[|\]|\)|,|:)\s*/);
        var outError = "";

        function returnNumElementInArray(inArray, element) {
            var numOfTrue = 0;
            for (var i = 0; i < inArray.length; i++) {
                if (inArray[i] === element)
                    numOfTrue++;
            }
            return numOfTrue;
        }

        if (returnNumElementInArray(tokens, "(") > returnNumElementInArray(tokens, ")")) {
            outError = "TooLittle)";
        } else if (returnNumElementInArray(tokens, "(") < returnNumElementInArray(tokens, ")")) {
            outError = "TooLittle(";
        } else if (tokens.indexOf(":") === -1 || tokens.indexOf("(") === -1 || tokens.indexOf(")") === -1 || isNaN(tokens[tokens.indexOf(":") + 1])) {
            outError = "NotNwk"
        }

        return outError;
    }
    function getIdxToken(tokenArray, queryToken) {
        var posTokens = [];
        for (var i = 0; i < tokenArray.length; i++) {
            if (tokenArray[i] === queryToken) {
                posTokens.push(i)
            }
        }
        return posTokens;
    }
    function convertTree(s) {
        var ancestors = [];
        var tree = {};
        var settingsLbls = [];

        s = s.replace(/(\r\n|\n|\r)/gm, "");

        var tokens = s.split(/\s*(;|\(|\[|\]|\)|,|:)\s*/);

        var nhx_tags = [':B', ':S', ':D', ':T', ':E', ':O', ':SO', ':L', ':Sw', ':CO', ':C'];

        var square_bracket_start = getIdxToken(tokens, "[");
        var square_bracket_end = getIdxToken(tokens, "]");
        var new_tokens = [];
        var j = 0;
        var i;
        for (i = 0; i < tokens.length; i++) {
            if (tokens[i] === "[") {
                var dist_square_bracket = square_bracket_end[j] - square_bracket_start[j];
                new_tokens.push(tokens[i]);
                new_tokens.push(tokens.slice(i + 1, i + dist_square_bracket).join(""));
                new_tokens.push(tokens[i + dist_square_bracket]);
                i = i + dist_square_bracket;
                j = j + 1;
            } else {
                new_tokens.push(tokens[i]);
            }
        }

        try { 
            if (tokens === "") {
                throw "empty";
            }
        } catch (err) {
            throw "NoTree";
        }

        try {
            if (checkTreeInput(s) === "TooLittle)") {
                throw "empty";
            }
        } catch (err) {
            throw "TooLittle)"
        }
        function is_nhx_tag_found(nhx_tags, tag_to_check) {
            return jQuery.inArray(":" + tag_to_check, nhx_tags);
        }
        for (i = 0; i < new_tokens.length; i++) {
            var token = new_tokens[i];
            var x;
            var subtree;
            switch (token) {
                case '(': 
                    subtree = {};
                    tree.children = [subtree];
                    ancestors.push(tree);
                    tree = subtree;
                    break;
                case ',': 
                    subtree = {};
                    ancestors[ancestors.length - 1].children.push(subtree);
                    tree = subtree;
                    break;
                case '[':
                    x = new_tokens[i + 1];
                    if (x.indexOf("&&NHX") !== -1) { 
                        var nhx_tokens = x.split(/:/);
                        jQuery.each(nhx_tokens, function (i, nhx_token) {
                            var token = nhx_token.split("=");
                            var tmp_idx = is_nhx_tag_found(nhx_tags, token[0])
                            if (tmp_idx !== -1) {
                                var nhxtag = nhx_tags[tmp_idx];
                                var nhxtag_value = token[1];
                                switch (nhxtag) {

                                    case ':B':
                                        settingsLbls.push('name');
                                        tree.branchSupport = nhxtag_value;
                                        break;

                                    case ':C':
                                        settingsLbls.push('color');
                                        tree.specifiedBranchColor = nhxtag_value;
                                        break;
                                    default:
                                        break;
                                }
                            }
                        });
                    } else {
                        if (!(x === ";" || x === "")) {
                            settingsLbls.push('name');
                            tree.branchSupport = x;
                        }
                    }
                    break;
                case ']':
                case ':':
                    break;
                case ')':
                    tree = ancestors.pop();
                    x = new_tokens[i + 1];
                    if (!(x === ";" || x === "")) {
                        settingsLbls.push('name');
                        tree.branchSupport = x;
                    }
                    break;
                default:
                    x = new_tokens[i - 1];
                    if (x === ')' || x === '(' || x === ',') {
                        var tree_meta = token.split("@@");
                        tree.name = tree_meta[0];
                        tree.length = 0.1;
                        tree.collapsed = false;

                    } else if (x === ':') {
                        tree.length = parseFloat(token);
                    }
            }
        }

        return tree;
    }

    function updateSettingsLabels(settingsLbls) {

        if (settingsLbls && settingsLbls.length > 0) {

            jQuery.each(settingsLbls, function (i, stglbl) {
                $('[name=internalLabels][value=' + stglbl + ']').show().next().show();
            });

        }
    }



    function resetTreeVisStatus(treeCollection) {
        if (treeCollection.length > 0) {
            for (var i = 0; i < treeCollection.length; i++) {
                treeCollection[i].display = false;
            }
        }
    }


    function getCollapsedTriangleLength(node) {
        var total = getTotalLength(node);
        var avg = total / node.leaves.length;
        return avg;
    }

    /**
     * @param {string} newick
     * @param {any} myName
     * @param {any} mode
     */
    function addTree(newick) {

        var num = trees.length;
        var idCounter = 0;

        var tmpNewicks;
        var newicks = [];
        const EON = newick.indexOf(";");
        tmpNewicks = newick.replace(/(^[ \t]*\n)/gm, "").replace(/(\r\n|\n|\r)/gm, (EON !== -1) ? "" : ";").split(";");
        if (tmpNewicks.length > 1) {
            newicks = tmpNewicks.slice(0, -1);
        }
        updateSettingsLabels();
        resetTreeVisStatus(trees);

        var i = 0;
        if (i == 0) {
            var count = (num + i);
            var name = "cloneid_" + count;
            var tree = convertTree(newicks[i]);
            var leaves = getChildLeaves(tree).sort();
            for (var j = 0; j < leaves.length; j++) {
                leaves[j].ID = Math.pow(2, j);
            }
            postorderTraverse(tree, function (d) {
                d.keep = true;
                d.ID = name + "_node_" + idCounter;
                d.leaves = getChildLeaves(d);
                d.clickedParentHighlight = false;
                d.mouseoverHighlight = false; 
                d.mouseoverLinkHighlight = false;
                d.correspondingHighlight = false;

                d.mouseoverLinkHighlight = true;

                d.collapsed = false;
                idCounter++;
            });

            var fullTree = {
                root: tree,
                name: name,
                display: true,
                part: i,
                last: (num + newicks.length - 1),
                data: {}
            };

            if (newicks.length > 1) {
                fullTree.multiple = true;
                fullTree.total = newicks.length;
            } else {
                fullTree.total = 1;
            }
            fullTree.data.autoCollapseDepth = getRecommendedAutoCollapse(tree);

            trees.push(fullTree);
        }
        return trees[0];
    }

    function getRecommendedAutoCollapse(root) {
        var leafCount = root.leaves.length;
        if (leafCount < 50) {
            return null;
        } else {
            return (Math.floor(Math.log(leafCount)) > 8 ? 10 : (Math.floor(Math.log(leafCount) + 3)));
        }

    }


    function findScaleValueBranchSupport(tree) {
        var branchSupport = [];
        postorderTraverse(tree, function (d) {
            if (d["branchSupport"]) {
                branchSupport.push(d["branchSupport"])
            }
        });
        var tmpMaxBranchSupport = Math.max.apply(Math, branchSupport);

        if (tmpMaxBranchSupport <= 1) {
            maxBranchSupport = 1
        } else if (tmpMaxBranchSupport <= 100) {
            maxBranchSupport = 100
        } else if (tmpMaxBranchSupport <= 1000) {
            maxBranchSupport = 1000
        }
        else {
            maxBranchSupport = undefined
        }

    }

    function getChildren(d) {
        return d._children ? d._children : (d.children ? d.children : []);
    }

    function getChildLeaves(d) {
        if (d.children || d._children) {
            var leaves = [];
            var children = getChildren(d);
            for (var i = 0; i < children.length; i++) {
                leaves = leaves.concat(getChildLeaves(children[i]));
            }
            return leaves;
        } else {
            return [d];
        }
    }

    function addParents(d) {
        var children = getChildren(d);
        for (var i = 0; i < children.length; i++) {
            children[i].parent = d;
            addParents(children[i]);
        }
    }

    function getMaxLengthVisible(root) {
        var max = 0;

        function getMax_internal(d, max) {
            if (d.children) {
                var children = d.children;
                for (var i = 0; i < children.length; i++) {
                    max = Math.max(getMax_internal(children[i], max), max)
                }
                return max;
            } else {
                var maxLength = (typeof d.triangleLength == 'undefined' || d.length > d.triangleLength) ? d.length : d.triangleLength;
                if (maxLength > max) {
                    longestNode = d;
                    return maxLength;
                }
                return max;
            }
        }

        return getMax_internal(root, max);
    }


    function getTotalLength(node) {
        var sum = 0;

        postorderTraverse(node, function (d) {
            sum += d.length;
        }, true);

        return sum;
    }

    function getLength(d) {
        if (d.parent) {
            return d.length + getLength(d.parent);
        } else {
            return 0;
        }
    }
    function postorderTraverse(d, f, do_children) {
        if (do_children === undefined) { 
            do_children = true;
        }
        var children = [];
        if (do_children) {
            children = getChildren(d);
        } else {
            if (d.children) {
                children = d.children
            }
        }
        if (children.length > 0) {
            for (var i = 0; i < children.length; i++) {
                postorderTraverse(children[i], f, do_children);
            }
            f(d);
            return;

        } else {
            f(d);
            return;
        }
    }

    function rgb2hex(rgbString) {

        var rgb = rgbString.split(".");

        var R = parseInt(rgb[0]);
        var G = parseInt(rgb[1]);
        var B = parseInt(rgb[2]);

        function componentToHex(c) {
            var hex = c.toString(16);
            return hex.length == 1 ? "0" + hex : hex;
        }

        return "#" + componentToHex(R) + componentToHex(G) + componentToHex(B);

    }



    var _UPPERBOUND_ = 0;
    function update(source, treeData, duration, treeToggle) {

        if (duration === undefined) {
            duration = 0;
        }

        var colorScale = d3.scale.linear()
            .domain(colorScaleDomain)
            .range(colorScaleRange);

        var colorScaleRest = d3.scale.linear()
            .domain(colorScaleDomain)
            .range(colorScaleRangeRest);

        var nodes = treeData.tree.nodes(treeData.root).reverse();
        var links = treeData.tree.links(nodes);

        var leaves = treeData.root.leaves.length;
        var leavesVisible = getVisibleLeaves(treeData.root);

        var height = $(".pedigreeTree").height();
        var renderHeight = height - paddingVertical * 2;
        var leavesHidden = 0;
        var triangles = 0;
        var colorInfo = {

            growthcurve: "black",
            timetable: "black",
            genotype: "black",
            seeding: "blue",
            harvest: "red",

            perspective: "purple",

            GenomePerspective: "#4a58dd",
            ExomePerspective: "#27d7c4",
            TranscriptomePerspective: "#95fb51",
            KaryotypePerspective: "#ffa423",
            MorphologyPerspective: "#ba2208",

        };

        postorderTraverse(treeData.root, function (d) {
            if (d._children) {
                leavesHidden += d.leaves.length;
                triangles += 1;
            }
        }, false);

        var newHeight;
        _UPPERBOUND_ = height;
        if (settings.fitTree === "scale" && treeData.prevNoLeavesVisible) {
            var newHeight = 1;
            if (leavesVisible > 0) {
                newHeight = renderHeight / (leavesVisible + leavesHidden);
                treeData.treeHeight = newHeight;
            }
        }
        if (settings.fitTree === "scale" && leavesVisible === 0 && !treeData.prevNoLeavesVisible) {
            newHeight = renderHeight / (leavesVisible + leavesHidden);
            newHeight = (newHeight * triangleHeightDivisor);
            newHeight = newHeight - (newHeight / triangleHeightDivisor / 2);
            treeData.treeHeight = newHeight;
        }
        if (leavesVisible > 0) {
            treeData.prevNoLeavesVisible = false;
        } else {
            treeData.prevNoLeavesVisible = true;
        }

        treeData.prevNoLeavesVisible = !(leavesVisible > 0);

        var leafHeight = treeData.treeHeight;
        height = leaves * leafHeight;
        var trianglePadding = leafHeight;
        var visNodes = 0;

        function getLeavesShown(e) {
            function getLeavesShownInner(d) {
                if (d.children) {
                    for (var i = 0; i < d.children.length; i++) {
                        getLeavesShownInner(d.children[i]);
                    }
                } else {
                    visNodes += 1;
                }
            }

            getLeavesShownInner(e);
            return visNodes;
        }
        
        function getCollapsedParams(e) {
            var collapsedHeightInner = 0;
            var leavesHiddenInner = 0;

            function getCollapsedHeight(d) {
                if (d._children && !d.children) {
                    var offset = leafHeight / triangleHeightDivisor * d.leaves.length;
                    if (offset < amendedLeafHeight) {
                        collapsedHeightInner += amendedLeafHeight;
                    } else {
                        collapsedHeightInner += ((leafHeight / triangleHeightDivisor * d.leaves.length) + (trianglePadding * 2));
                    }
                    leavesHiddenInner += d.leaves.length;
                } else if (d.children) {
                    for (var i = 0; i < d.children.length; i++) {
                        getCollapsedHeight(d.children[i]);
                    }
                }
            }

            getCollapsedHeight(e);
            return {
                collapsedHeight: collapsedHeightInner,
                leavesHidden: leavesHiddenInner
            }
        }

        const root_leaves_length = treeData.root.leaves.length;
        var allVisLeaves = getLeavesShown(treeData.root);
        
        var divisor = (root_leaves_length - allVisLeaves) > 0
            ?
            allVisLeaves
            :
            root_leaves_length;


        var params = getCollapsedParams(treeData.root);
        var collapsedHeight = params.collapsedHeight;
        collapsedHeight = 0;
        
        var amendedLeafHeight = ((root_leaves_length * leafHeight) - collapsedHeight) / (divisor);
        

        settings.loadingCallback();
        
        
        var test = 0;
        function setXPos(d, upperBound) {

            _UPPERBOUND_ = Math.min(_UPPERBOUND_, upperBound);
            

            var params;
            var collapsedHeight;

            if (d.children) {
                for (var i = 0; i < d.children.length; i++) {
                    setXPos(d.children[i], upperBound);
                    test += 1;
                    params = getCollapsedParams(d.children[i]);
                    collapsedHeight = params.collapsedHeight;
                    var leavesHidden = params.leavesHidden;
                    upperBound -= (((d.children[i].leaves.length - leavesHidden) * amendedLeafHeight) + collapsedHeight);
                }
                d.x = d.children[0].x + ((d.children[d.children.length - 1].x - d.children[0].x) / 2);
            } else if (d._children) {
                
                params = getCollapsedParams(d);
                collapsedHeight = params.collapsedHeight;
                d.x = upperBound + (collapsedHeight / 2);
            } else {
                
                d.x = upperBound + (amendedLeafHeight / 2);
            }
            d.x = d.x;
        }


        var maxLength = treeData.maxLength;
        



        var lengthMult = treeData.treeWidth;
        


        var newLenghtMult = 0;
        nodes.forEach(function (d) {
            if (settings.useLengths) {
                d.y = getLength(d) * (lengthMult / maxLength) / 2; 
                d.baseY = d.y;
            } else {
                d.y = d.depth * lengthMult / 10;
                d.baseY = d.y;
                if (d.y > newLenghtMult) {
                    newLenghtMult = d.y
                }
            }
            d.y = d.y - 90;
        });

        if (newLenghtMult > lengthMult) {
            lengthMult = newLenghtMult
        }

        var xxheight = settings.callbackD();
        setXPos(treeData.root, xxheight);
        var node = treeData.svg.selectAll("g.node")
            .data(nodes, function (d) {
                return d.id || (d.id = ++treeData.i);
            })
            .attr("id", function (d) {
                return d.ID;
            });
        var nodeEnter = node.enter().append("g")
            .filter(function (d) { return d.keep })
            .attr("class", "node")
            .attr("id", function (d) {
                return d.ID;
            })
            .on("mouseover", nodeMouseover)
            .on("mouseout", nodeMouseout)
            .on("click", treeData.clickEvent)
            .on("dblclick", (e) => { if (e.preventDefault) e.preventDefault(); if (e.stopPropagation) e.stopPropagation(); })
            .on("contextmenu", treeData.clickEvent)
            ;

        if (true) {
            nodeEnter.append("text")
                .attr("class", function (d) {
                    return "node";
                })
                .attr("dy", function (d) {
                    return "6px";
                })
                .attr("text-anchor", function (d) {
                    return "start";
                })
                .style("fill-opacity", 1.0)
                .style("fill", function (/** @type {{ name: any; }} */ d) {
                    if (settings.callbackI(d.name)) {
                        return colorInfo.seeding;
                    } else {
                        return colorInfo.harvest;
                    }
                })
                .style("cursor", function (/** @type {{ name: any; }} */ d) {
                    return "pointer";
                })
                ;
        }
        // GROWTH CURVE ICON
        if (true || capableOf('C')) {
            nodeEnter.append("circle")
                .attr("class", "node")
                .attr("x", function (d) {
                    return "30px";
                })
                .attr("r", function (d) {
                    if (settings.callbackH(d.name)) {
                        return '5.5';
                    }
                    return '0.01';
                })
                .style("fill", function (d) {
                    return colorInfo.growthcurve;
                });
        }
        // TIMETABLE ICON
        if (true || capableOf('T')) {
            nodeEnter.append("path")
                .attr("class", "triangle")
                .attr("x", function (d) {
                    if (d.icons) {
                        d.icons++;
                        return 10 + (d.icons + 1) * 10 * settings.nodeSize + "px";
                    } else {
                        d.icons = 1;
                        return '100px';
                    }
                })
                .attr("d", function (d) {
                    if (settings.callbackI(d.name)) {
                        return "M0 0 L-6 -10 L6 -10 Z";
                    }
                    return "M0,0Z";
                })
                .attr("transform", function (d) {
                    return "translate(" + 15 + "," + 5 + ")";
                })
                .style("fill", function (d) {
                    return colorInfo.timetable;
                })
                ;
        }

        // GENOTYPE ICON
        if (true || capableOf('G') && settings.callbackG()) {
            const perspkeys = Object.keys(perspectiveLabelColor1);
            for (let index = 0; index < perspkeys.length; index++) {
                nodeEnter.append("rect")
                    .attr("class", "node")
                    .attr("y", "-5px")
                    .attr("x", function (d) {
                        const p1 = settings.callbackG(d.name);
                        if (p1) {
                            if (p1.includes(perspkeys[index])) {
                                if (d.icons) {
                                    d.icons++;
                                    return (d.icons) * 15 + "px";
                                } else {
                                    d.icons = 1;
                                    return '0px';
                                }
                            } else {
                                return "0px";
                            }
                        } else {
                            return "0px";
                        }
                    })
                    .attr("width", function (d) {
                        const p1 = settings.callbackG(d.name);
                        if (p1) {
                            if (p1.includes(perspkeys[index])) {
                                return "15px";
                            } else {
                                return "0px";
                            }
                        } else {
                            return "0px";
                        }
                    })
                    .attr("height", function (d) {
                        const p1 = settings.callbackG(d.name);
                        if (p1) {
                            if (p1.includes(perspkeys[index])) {
                                return "15px";
                            } else {
                                return "0px";
                            }
                        } else {
                            return "0px";
                        }
                    })
                    .style("fill", function (d) {
                        const p1 = settings.callbackG(d.name);
                        if (p1) {
                            if (p1.includes(perspkeys[index])) {
                                return perspectiveLabelColor[perspkeys[index]];
                            }
                        } else {
                            return "black";
                        }
                        return p1 ? perspectiveLabelColor1[perspkeys[index]] : "black";
                    });
            }
        }

        if (true) {
            var nodeUpdate = node.transition()
                .duration(duration)
                .attr("transform", function (d) {
                    return "translate(" + d.y + "," + d.x + ")";
                });
        }
        if (true) {
            nodeUpdate.select("text")
                .style("fill-opacity", 1.0)
                .attr("dx", function (d) {
                    if (!d.children && !d._children) {
                        const p1 = settings.callbackG(d.name) ? settings.callbackG(d.name).length : 0;
                        const p2 = settings.callbackH(d.name) ? 1 : 0;
                        const p3 = settings.callbackI(d.name) ? 1 : 0;
                        return (d.icons && d.icons > 0) ? ((d.icons + 1) * 20 + "px") : "20px";
                    } else {
                        return 0;
                    }
                })
                .text(function (d) {
                    if (!d.children && !d._children) {
                        return d.name;
                    } else {
                        return "";
                    }
                });
        }
        node.select("text")
            .attr("font-family", "Arvo")
            .attr("font-weight", "900")
            .attr("font-size", settings.fontSize + "px");

        function renderLinks(type) {
            var select = (type === "bg") ? "linkbg" : "link";
            var link = treeData.svg.selectAll("path." + select)
                .data(links, function (d) {
                    return d.target.id;
                })
                .attr("id", function (d) {
                    return d.source.ID + '_' + d.target.ID;
                })
                .style("stroke", function (d) {
                    var e = d.target;
                    var f = d.source;
                    if (f[currentS] && (settings.internalLabels === "none")) {
                        return colorScale(e[currentS])
                    } else if (e["branchSupport"] && (settings.internalLabels === "name")) {
                        return colorScaleRest(parseFloat(e["branchSupport"]) / maxBranchSupport)
                    } else if (e["specifiedBranchColor"] && (settings.internalLabels === "color")) {
                        return rgb2hex(e["specifiedBranchColor"])
                    } else {
                        return "black"
                    }
                });
            link.enter().insert("path", "g")
                .attr("class", function (d) {
                    if (type === "bg") {
                        return "linkbg";
                    } else {
                        return "link";
                    }
                })
                .attr("id", function (d) {
                    return d.source.ID + '_' + d.target.ID;
                })
                .attr("d", function (d) {
                    d = d.source;
                    var output;
                    if (source === treeData.root) {
                        if (d.parent) {
                            output = "M" + d.parent.y + "," + d.parent.x + "L" + d.parent.y + "," + d.parent.x + "L" + d.parent.y + "," + d.parent.x;
                        } else {
                            output = "M" + source.y + "," + source.x + "L" + source.y + "," + source.x + "L" + source.y + "," + source.x;
                        }
                    } else {
                        output = "M" + source.y + "," + source.x + "L" + source.y + "," + source.x + "L" + source.y + "," + source.x;
                    }
                    return output;
                })
                .style("stroke-width", function () {
                    if (type === "bg") {
                        return (parseInt(settings.lineThickness) + 2);
                    } else if (type === "front") {
                        return settings.lineThickness;
                    }
                })
                .style("stroke", function (d) {
                    var e = d.target;
                    var f = d.source;
                    if (f[currentS] && (settings.internalLabels === "none")) {
                        return colorScale(f[currentS])
                    } else if (e["branchSupport"] && (settings.internalLabels === "name")) {
                        return colorScaleRest(parseFloat(e["branchSupport"]) / maxBranchSupport)
                    } else if (e["specifiedBranchColor"] && (settings.internalLabels === "color")) {
                        return rgb2hex(e["specifiedBranchColor"])
                    } else {
                        return "black"
                        return "purple"
                    }
                })

            link.select("rect")
                .attr("width", function (d) {
                    if (d.clickedHighlight) {
                        return (settings.nodeSize * 2) + "px";
                    } else {
                        return "0px";
                    }
                })
                .attr("height", function (d) {
                    if (d.clickedHighlight) {
                        return (settings.nodeSize * 2) + "px";
                    } else {
                        return "0px";
                    }
                })
                .style("fill", function (d) {
                    if (d.clickedHighlight) {
                        return d.clickedHighlight;
                    }
                })
                .attr("y", -settings.nodeSize + "px")
                .attr("x", -settings.nodeSize + "px");

            link.transition()
                .duration(duration)
                .style("stroke-width", function () {
                    if (type === "bg") {
                        return (parseInt(settings.lineThickness) + 2);
                    } else if (type === "front") {
                        return settings.lineThickness;
                    }
                })
                .attr("d", function (d) {
                    return "M" + d.source.y + "," + d.source.x + "L" + d.source.y + "," + d.target.x + "L" + d.target.y + "," + d.target.x;
                });

            link.exit().transition()
                .duration(duration)
                .attr("d", function (d) {
                    d = d.source;
                    if (source === treeData.root) {
                        var e = findHighestCollapsed(d);
                        return "M" + e.y + "," + e.x + "L" + e.y + "," + e.x + "L" + e.y + "," + e.x;
                    } else {
                        return "M" + source.y + "," + source.x + "L" + source.y + "," + source.x + "L" + source.y + "," + source.x;
                    }
                })
                .remove();
        }

        if (true) renderLinks("front");

        nodes.forEach(function (d) {
            d.x0 = d.x;
            d.y0 = d.y;
        });

        function nodeMouseover(d) {
            function colorLinkNodeOver(n) {
                if (n.children) {
                    for (var i = 0; i < n.children.length; i++) {
                        d3.select("#" + n.ID + "_" + n.children[i].ID).classed("select", true);
                        colorLinkNodeOver(n.children[i]);
                    }
                }
                if (!settings.enableFisheyeZoom) {
                    d3.select("g").select("#" + n.ID).classed("select", true);
                    d3.select("#" + n.ID).select("text").classed("select", true);
                }
            }
            colorLinkNodeOver(d);
        }

        function nodeMouseout(d) {
            function colorLinkNodeOver(n) {
                if (n.children) {
                    for (var i = 0; i < n.children.length; i++) {
                        d3.select("#" + n.ID + "_" + n.children[i].ID).classed("select", false);
                        colorLinkNodeOver(n.children[i]);
                    }
                }
                if (!settings.enableFisheyeZoom) {
                    d3.select("g").select("#" + n.ID).classed("select", false);
                    d3.select("#" + n.ID).select("text").classed("select", false);
                    d3.select("#" + n.ID).select("circle").classed("select", false);
                    d3.select("#" + n.ID).select("rect").classed("select", false);
                    d3.select("#" + n.ID).select("path").classed("select", false);
                    d3.select("#" + n.ID).select(".triangleText").classed("select", false);
                    d3.select("#" + n.ID).select(".triangle").classed("select", false);
                }
            }
            colorLinkNodeOver(d);
        }


        $('html').click(function (d) {
            if ((d.target.getAttribute("class") !== "link" && d.target.getAttribute("class") !== "node" && d.target.getAttribute("class") !== "link search" && d.target.getAttribute("class") !== "node select")) {
                settings.callbackL(null, null);
            }
        });

        settings.loadedCallback();
    }


    /**
     * @param {{ id: string; zoomBehaviour: { scale: (arg0: string | number | string[] | undefined) => void; event: (arg0: any) => void; }; svg: any; }} treeData
     */
    function applyEventListeners(treeData) {
        var setScaleCallBack = (x, t) => {
            var canvasWidth = $("#pedigreeTree").width();
            var canvasHeight = $("#pedigreeTree").height();

            var z1 = t.zoomBehaviour.scale(x);

            var visibleLeaves = getVisibleLeaves(t.root);
            var leafHeight = settings.treeHeight;
            var _treeHeight = visibleLeaves * leafHeight;
            var deltay = _treeHeight - canvasHeight;
            let sc = canvasHeight / _treeHeight;

            let dx = 100;
            let dy = deltay * x;

            t.zoomBehaviour.translate([dx, dy]);
            const z = d3.select("#" + t.canvasId + " svg g")
                .attr("transform", "translate(" + [dx, dy] + ") scale(" + x + ")");
        };

        settings.callbackB(setScaleCallBack, treeData);

        $("#zoomSlider" + treeData.id)
            .on("input change", function () {
                treeData.zoomBehaviour.scale($("#zoomSlider" + treeData.id).val());
                treeData.zoomBehaviour.event(treeData.svg);
                if (settings.enableZoomSliders) {
                    $("#zoomSlider" + treeData.id).val(scale);
                }
            });
    }
    function findHighestCollapsed(d) {
        if (d.parent) {
            if (d._children && d.parent.children) {
                return d;
            } else {
                return (findHighestCollapsed(d.parent));
            }
        } else {
            return d;
        }
    }
    function initializeRenderTreeCanvas(name, canvasId, scaleId, otherTreeName) {

        var baseTree = trees[findTreeIndex(name)];
        if (otherTreeName !== undefined) {
            compareMode = true;
        }

        $("#" + canvasId).empty();
        jQuery.extend(baseTree.data, {
            canvasId: canvasId
        });

        if (scaleId && settings.enableScale) {
            $("#" + scaleId).empty();
            jQuery.extend(baseTree.data, {
                scaleId: scaleId
            });
        }
    }

    function renderTree(baseTree, name, canvasId, scaleId, otherTreeName, treeToggle) {
        compareMode = false;

        if (scaleId && settings.enableScale) {
            $("#" + scaleId).empty();
            scaleId = "#" + scaleId;
        }

        var width = $("#" + canvasId).width();
        var height = $("#" + canvasId).height();
        var tree = d3.layout.tree()
            .size([height, width]);

        var svg = d3.select("#" + canvasId).append("svg")
            .attr("width", width)
            .attr("height", height)
            .attr("version", "1.1")
            .attr("xmlns", "http://www.w3.org/2000/svg")
            .attr("id", name)
            .append("g");


        var zoomBehaviour = d3.behavior.zoom()
            .scaleExtent([settings.scaleMin, settings.scaleMax])
            .on("zoom", zoom);

        if (settings.zoomMode === "traditional") {
            d3.select("#" + canvasId + " svg")
                .call(zoomBehaviour)
                .on("dblclick.zoom", (e) => {
                    if (e && e.preventDefault) e.preventDefault();
                    if (e && e.stopPropagation) e.stopPropagation();
                })
                .on("dblclick", (e) => { if (e && e.preventDefault) e.preventDefault(); if (e && e.stopPropagation) e.stopPropagation(); })
        }
        var root = baseTree.root;
        root.x0 = height / 1;
        root.y0 = 0;

        jQuery.extend(baseTree.data, {
            canvasId: canvasId,
            root: root,
            tree: tree,
            svg: svg,
            i: 0,
            id: findTreeIndex(name),
            zoomBehaviour: zoomBehaviour,
        });

        postorderTraverse(baseTree.data.root, function (d) {
            d.leaves = getChildLeaves(d);
            d.mouseoverHighlight = false;
            if (d.children || d._children) {
                d.triangleLength = getCollapsedTriangleLength(d);
            }
        });

        applyEventListeners(baseTree.data);
        jQuery.extend(baseTree.data, {
            treeWidth: settings.treeWidth,
            treeHeight: settings.treeHeight
        });

        if (settings.fitTree === "scale") {
            var renderHeight = height - paddingVertical * 2;
            var leavesVisible = getVisibleLeaves(baseTree.root);
            var leavesHidden = 0;
            var triangles = 0;
            postorderTraverse(baseTree.root, function (d) {
                if (d._children) {
                    leavesHidden += d.leaves.length;
                    triangles += 1;
                }
            }, false);


            var newHeight;
            if (leavesVisible > 0) {
                newHeight = renderHeight / (leavesVisible / 2);
            }

            var longest = 0;
            addParents(baseTree.data.root);
            postorderTraverse(baseTree.data.root, function (d) {
                var l = getLength(d);
                if (l > longest) {
                    longest = l;
                }
            });

            maxLength = getMaxLengthVisible(baseTree.data.root);
            baseTree.data.maxLength = getLength(longestNode);
            baseTree.data.treeWidth = width;
        }

        update(baseTree.root, baseTree.data, undefined, treeToggle);

        if (settings.callbackK(0)) {

            let dx = 80;
            var canvasWidth = $("#" + canvasId).width();
            var canvasHeight = $("#" + canvasId).height();
            var visibleLeaves = getVisibleLeaves(baseTree.data.root);
            var leafHeight = settings.treeHeight;
            var _treeHeight = visibleLeaves * leafHeight;
            var deltay = _treeHeight - canvasHeight;
            let sc = canvasHeight / _treeHeight;

            let dy = deltay * sc;

            baseTree.data.zoomBehaviour.translate([dx, dy + 0]);
            baseTree.data.zoomBehaviour.scale(sc);
            d3.select("#" + baseTree.data.canvasId + " svg g")
                .attr("transform", "translate(" + [dx, dy] + ") scale(" + sc + ")");
            settings.callbackA(sc);
        } else {
            var canvasWidth = $("#" + canvasId).width();
            var canvasHeight = $("#" + canvasId).height();
            var visibleLeaves = getVisibleLeaves(baseTree.data.root);
            var leafHeight = settings.treeHeight;
            var _treeHeight = visibleLeaves * leafHeight;
            var deltay = _treeHeight - canvasHeight;

            const dx = 100;
            const dy = deltay;
            const sc = 1.0;

            baseTree.data.zoomBehaviour.translate([dx, dy]);
            baseTree.data.zoomBehaviour.scale(sc);

            settings.callbackA(sc);
            d3.select("#" + baseTree.data.canvasId + " svg g")
                .attr("transform", "translate(" + [dx, dy] + ") scale(" + sc + ")");
        }

        function zoom() {

            var scale = d3.event.scale;
            var translation = d3.event.translate;
            zoomBehaviour.translate(translation);
            zoomBehaviour.scale(scale);
            if (settings.enableScale) {
                settings.callbackA(scale);
            }

            const x = d3.select("#" + baseTree.data.canvasId + " svg g")
                .attr("transform", "translate(" + [translation[0], translation[1]] + ") scale(" + scale + ")");

        }
    }

    function getVisibleLeaves(d) {
        var visible = 0;
        postorderTraverse(d, function (e) {
            var children = getChildren(e);
            if (children.length === 0) {
                visible += 1;
            }
        }, false);
        return visible;
    }

    function findTreeIndex(name) {
        for (var i = 0; i < trees.length; i++) {
            if (name === trees[i].name) {
                return i;
            }
        }
    }

    function initialiseTree(tree, autocollapse) {
        findScaleValueBranchSupport(tree);
        uncollapseAll(tree);
        stripPreprocessing(tree);
        getDepths(tree);

        postorderTraverse(tree, function (d) {
            if (d.name === "collapsed" || d.collapsed) {
                d._children = d.children;
                d.collapsed = true;
                d.children = null;
            }
        });

        if (autocollapse !== null) {
            limitDepth(tree, autocollapse);
        }
    }

    function viewTree(name, canvasId, scaleId) {
        renderedTrees = [];
        var index = findTreeIndex(name);
        initializeRenderTreeCanvas(name, canvasId, scaleId);
        initialiseTree(trees[index].root, settings.autoCollapse);
        trees[index].data.clickEvent = getClickEventListenerNode(trees[index], false, {});
        renderTree(trees[index], name, canvasId, scaleId);

    }

    function zoomCallback(x) {
        const treeData = trees[0];
        if (treeData && treeData.zoomBehaviour && treeData.zoomBehaviour.scale) {
            treeData.zoomBehaviour.scale(x);
            treeData.zoomBehaviour.event(treeData.svg);
        }
    }

    function limitDepth(d, depth) {
        if (d.depth > depth) {
            if (d.children) {
                d._children = d.children;
                d.children = null;
                d.collapsed = true;
            }
        } else {
            uncollapseNode(d);
        }
        var children = getChildren(d);
        for (var i = 0; i < children.length; i++) {
            limitDepth(children[i], depth);
        }
    }

    function uncollapseAll(root, tree) {
        postorderTraverse(root, uncollapseNode);
        if (tree !== undefined) {
            update(root, tree.data);
        }
    }

    function uncollapseNode(d) {
        if (d._children) {
            d.children = d._children;
            d._children = null;
        }
    }

    function stripPreprocessing(root) {
        postorderTraverse(root, function (d) {
            d.elementBCN = null;
            d.elementS = null;
            d.x = null;
            d.y = null;
            d.x0 = null;
            d.y0 = null;
            d.source = null;
            d.target = null;
            d.baseX = null;
            d.baseY = null;
            d.id = null;
        });
    }

    function getDepths(root, inc) {
        if (inc === undefined) {
            inc = 0;
        }
        root.depth = inc;
        var children = getChildren(root);
        inc += 1;
        for (var i = 0; i < children.length; i++) {
            getDepths(children[i], inc);
        }
    }


    function getClickEventListenerNode(tree, isCompared, comparedTree) {
        var treeIndex = findTreeIndex(tree.name);
        function nodeClick(d) {

            var event = d3.event;
            event.preventDefault();
            event.stopPropagation();

            settings.callbackL(null, null);

            d3.selection.prototype.moveToFront = function () {
                return this.each(function () {
                    this.parentNode.appendChild(this);
                });
            };

            if (!d.children && !d._children) {
                settings.callbackL(event, d);
            }

        }
        return nodeClick;
    }

    return {
        init: init,
        viewTree: viewTree,
        addTree: addTree,
        zoomCallback: zoomCallback,
    }
};
