import commands from "./commands.js";
import History from "./history.js";

let history = new History();
let tempValue = null;

const promptElement = document.querySelector("#prompt input");
const outputElement = document.querySelector("#output");

outputElement.innerHTML = "<div>type <span style='color: #808080'>help</span> to see all commands</div>";

window.addEventListener("keydown", (e) => {
	if (!e.ctrlKey && !e.metaKey) {
		promptElement.focus();
	}
});

window.addEventListener("keydown", (e) => {
	if (e.ctrlKey && e.key === "l") {
		outputElement.innerHTML = "";
	}

	if (e.ctrlKey && e.key === "c" && window.getSelection().toString().length === 0) {
		outputElement.innerHTML += `<div>$ ${promptElement.value}</div>`;
		promptElement.value = "";
		window.scrollTo(0, document.body.scrollHeight);
	}
});

window.addEventListener("keydown", (e) => {
	if (e.key === "ArrowUp" || (e.ctrlKey && e.key === "p")) {
		const entry = history.prev();
		if (entry !== null) {
			if (tempValue === null) {
				tempValue = promptElement.value;
			}
			promptElement.value = entry;
		}
	}

	if (e.key === "ArrowDown" || (e.ctrlKey && e.key === "n")) {
		const entry = history.next();
		if (entry !== null) {
			promptElement.value = entry;
		} else {
			if (tempValue !== null) {
				promptElement.value = tempValue;
				tempValue = null;
			}
		}
	}
});

window.addEventListener("keydown", async (e) => {
	if (e.key !== "Enter") return;

	const value = promptElement.value;

	outputElement.innerHTML += `<div>$ ${value}</div>`;
	promptElement.value = "";

	history.add(value);

	const argv = value
		.trim()
		.split(" ")
		.filter((arg) => arg.length > 0);

	if (Object.keys(commands).includes(argv[0])) {
		const out = await commands[argv[0]].action(argv);
		if (out != null) {
			outputElement.innerHTML += out;
		}
	} else if (argv.length != 0) {
		outputElement.innerHTML += `<div>command not found: ${argv[0]}</div>`;
	}

	window.scrollTo(0, document.body.scrollHeight);
});
