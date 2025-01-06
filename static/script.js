(async () => {
	const prompt = document.querySelector("#prompt");
	const output = document.querySelector("#output");
	const promptPrefix = "$ ";
	const res = await fetch("./data.json");
	const data = await res.json();

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
				output.innerHTML += `<div>${data.about}</div>`;
			},
		},
		contact: {
			description: "display contact info",
			call: (_, output) => {
				output.innerHTML += `<div><a href="mailto:${data.contact.email}">󰇮 ${data.contact.email}</a></div>`;
				output.innerHTML += `<div><a href="phone:${data.contact.phone}"> ${data.contact.phone}</a></div>`;
				output.innerHTML += `<div><a href="${data.contact.github}"> ${data.contact.github}</a></div>`;
				output.innerHTML += `<div><a href="${data.contact.linkedin}"> ${data.contact.linkedin}</a></div>`;
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

	prompt.value = promptPrefix;

	prompt.addEventListener("click", () => {
		if (prompt.selectionStart < promptPrefix.length) {
			prompt.setSelectionRange(promptPrefix.length, promptPrefix.length);
		}
	});

	prompt.addEventListener("keydown", (event) => {
		const caretPos = prompt.selectionStart;
		if (event.key === "Backspace" && caretPos <= promptPrefix.length) {
			event.preventDefault();
		} else if (
			(event.key === "ArrowLeft" || event.key === "ArrowUp" || event.key === "Home") &&
			caretPos <= promptPrefix.length
		) {
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
})();
