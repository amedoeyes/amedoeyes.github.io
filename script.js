import commands from "./commands.js";

const promptElement = document.querySelector("#prompt input");
const outputElement = document.querySelector("#output");

outputElement.innerHTML = "<div>type <span style='color: #808080'>help</span> to see all commands</div>";

window.onkeydown = (e) => {
	if (e.ctrlKey) {
		if (e.key === "l") {
			outputElement.innerHTML = "";
		} else if (e.key === "c" && window.getSelection().toString().length == 0) {
			outputElement.innerHTML += `<div>$ ${promptElement.value}</div>`;
			promptElement.value = "";
			window.scrollTo(0, document.body.scrollHeight);
		}
	} else {
		promptElement.focus();
	}
};

promptElement.addEventListener("keydown", (e) => {
	if (e.key === "Enter") {
		outputElement.innerHTML += `<div>$ ${promptElement.value}</div>`;

		const argv = promptElement.value
			.trim()
			.split(" ")
			.filter((arg) => arg.length > 0);
		promptElement.value = "";

		if (Object.keys(commands).includes(argv[0])) {
			const out = commands[argv[0]].action(argv);
			if (out != null) {
				outputElement.innerHTML += out;
			}
		} else if (argv.length != 0) {
			outputElement.innerHTML += `<div>command not found: ${argv[0]}</div>`;
		}

		window.scrollTo(0, document.body.scrollHeight);
	}
});
