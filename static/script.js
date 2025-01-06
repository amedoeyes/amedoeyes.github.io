const prompt = document.querySelector("#prompt");
const output = document.querySelector("#output");
const promptPrefix = "$ ";
prompt.value = promptPrefix;

const commands = {
	echo: {
		description: "display a line of text",
		call: (argv, output) => {
			output.innerHTML += `<div>${argv.slice(1).join(" ")}</div>`;
		},
	},
	clear: {
		description: "clear the terminal screen",
		call: (_, output) => {
			output.innerHTML = "";
		},
	},
	about: {
		description: "display info about me",
		call: (_, output) => {
			output.innerHTML += `<div>Hi. I'm Ahmed AbouEleyuon, a software developer, and a post graduate computer science student at Cairo University. I like low-level and graphics programming, open source, and terminals (haha). I use Arch Linux (BTW), and Neovim. And I love cats.</div>`;
		},
	},
	help: {
		description: "display this help message",
		call: (_, output) => {
			let max_len = 0;
			for (const cmd in commands) max_len = Math.max(max_len, cmd.length);
			for (const cmd in commands) {
				output.innerHTML += `<div>${cmd + " ".repeat(max_len - cmd.length + 4) + commands[cmd].description}</div>`;
			}
		},
	},
};

window.onload = () => {
	prompt.setSelectionRange(promptPrefix.length, promptPrefix.length);
};

window.onkeydown = () => {
	prompt.focus();
};

prompt.addEventListener("click", () => {
	if (prompt.selectionStart < promptPrefix.length) {
		prompt.setSelectionRange(promptPrefix.length, promptPrefix.length);
	}
});
prompt.addEventListener("keydown", (event) => {
	const caretPos = prompt.selectionStart;
	if (event.key === "Backspace" && caretPos <= promptPrefix.length) {
		event.preventDefault();
	} else if ((event.key === "ArrowLeft" || event.key === "Home") && caretPos <= promptPrefix.length) {
		event.preventDefault();
	}
});

prompt.addEventListener("keydown", (event) => {
	if (event.key === "Enter") {
		output.innerHTML += `<div>${prompt.value}</div>`;
		argv = prompt.value
			.trim()
			.substring(2)
			.split(" ")
			.filter((arg) => arg.length > 0);
		if (Object.keys(commands).includes(argv[0])) commands[argv[0]].call(argv, output);
		else output.innerHTML += `<div>command not found: ${argv[0]}</div>`;
		window.scrollTo(0, document.body.scrollHeight);
		prompt.value = promptPrefix;
	}
});
