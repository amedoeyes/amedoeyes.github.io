import commands from "./commands.js";

const promptElement = document.querySelector("#prompt input");
const outputElement = document.querySelector("#output");

outputElement.innerHTML = "<div>type <span style='color: #808080'>help</span> to see all commands</div>";

promptElement.addEventListener("keydown", (event) => {
	if (event.key === "Enter") {
		outputElement.innerHTML += `<div>$ ${promptElement.value}</div>`;

		const argv = promptElement.value
			.trim()
			.split(" ")
			.filter((arg) => arg.length > 0);
		promptElement.value = "";

		if (Object.keys(commands).includes(argv[0])) {
			commands[argv[0]].action(argv, outputElement);
		} else if (argv.length != 0) {
			outputElement.innerHTML += `<div>command not found: ${argv[0]}</div>`;
		}

		window.scrollTo(0, document.body.scrollHeight);
	}
});
