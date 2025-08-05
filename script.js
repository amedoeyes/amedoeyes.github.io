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

	if (e.ctrlKey && e.key === "d") {
		window.open("", "_self").close();
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

	let out = null;
	if (Object.keys(commands).includes(argv[0])) {
		out = await commands[argv[0]].action(argv);
	} else if (argv.length != 0) {
		out = `<div>command not found: ${argv[0]}</div>`;
	}

	if (out != null) {
		outputElement.innerHTML += out;

		const lastElement = outputElement.lastElementChild;
		const img = lastElement.querySelector("img:last-child");

		if (img && !img.complete) {
			img.onload = () => {
				window.scrollTo(0, document.body.scrollHeight);
			};
		}

		window.scrollTo(0, document.body.scrollHeight);
	}
});
