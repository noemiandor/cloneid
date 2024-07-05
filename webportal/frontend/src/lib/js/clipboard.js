/**
	 * @param {string} text
	 */
export function setClipBoard(text, type = "text/plain") {
    var blob = new Blob([text], { type });
    var data = [new ClipboardItem({ [type]: blob })];
    navigator.clipboard.write(data).then(
        function () {
            console.log("TO CLIPBOARD:",text);
            return;
        },
        function () {
            throw text;
        }
    );
}