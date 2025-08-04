import commands from "./commands.js";

const history = [];
let histIdx = -1;
let histTemp = null;

const promptElement = document.querySelector("#prompt input");
const outputElement = document.querySelector("#output");

outputElement.innerHTML = "<div>type <span style='color: #808080'>help</span> to see all commands</div>";

window.onkeydown = (e) => {
	if (e.ctrlKey && e.key === "l") {
		outputElement.innerHTML = "";
	}

	if (e.ctrlKey && e.key === "c" && window.getSelection().toString().length == 0) {
		outputElement.innerHTML += `<div>$ ${promptElement.value}</div>`;
		promptElement.value = "";
		window.scrollTo(0, document.body.scrollHeight);
	}

	if (e.ctrlKey && e.key === "w") {
		outputElement.innerHTML = "";
	}

	if ((e.key === "ArrowUp" || (e.ctrlKey && e.key == "p")) && histIdx < history.length - 1) {
		if (histIdx == -1) {
			histTemp = promptElement.value;
		}
		histIdx += 1;
		promptElement.value = history[histIdx];
	}

	if ((e.key === "ArrowDown" || (e.ctrlKey && e.key == "n")) && histIdx > -1) {
		histIdx -= 1;
		if (histIdx == -1) {
			promptElement.value = histTemp;
			histTemp = null;
		} else {
			promptElement.value = history[histIdx];
		}
	}

	if (!e.ctrlKey) {
		promptElement.focus();
	}
};

promptElement.addEventListener("keydown", async (e) => {
	if (e.key === "Enter") {
		const value = e.target.value;

		history.unshift(value);
		histIdx = -1;

		outputElement.innerHTML += `<div>$ ${value}</div>`;
		promptElement.value = "";

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
	}
});
