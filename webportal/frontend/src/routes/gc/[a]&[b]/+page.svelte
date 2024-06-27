<script>
	/** @type {import('./$types').PageData} */
	export let data;

	import { browser } from '$app/environment';
	import { goto } from '$app/navigation';
	import { sessionStore } from '$lib/js/session';
	let k = data.k;
	let v = data.v;

	let gcinfo = {};

	onMount(() => {
		if (browser) {
			gc();
		}
	});

	function decoderesponse(x) {
		const kv = JSON.parse(x.data);
		const k = kv[0];
		let d = {};
		for (let [k1, v1] of Object.entries(k)) {
			d[k1] = kv[v1];
		}
		return d;
	}

	async function gc() {
		const formData = new FormData();
		formData.append('k', k);
		formData.append('v', v);
		gcinfo = await fetch('?/gc', {
			method: 'POST',
			body: formData
		})
			.then(async (res) => {
				const r = await res.json();
				let d = {};
				if (r.type === 'success' && r.status === 200) {
					d = decoderesponse(r);
					const j = JSON.parse(d.d);
					console.log('D', j);
					return j;
				} else {
					throw res;
				}
			})
			.catch(async (e) => {
				console.log('e', e);
			});
		if (gcinfo.auth !== '') {
			sessionStore('cloneid', 'on');
			sessionStore('user', gcinfo.auth);
			goto(gcinfo.url);
		}
		if (gcinfo.type === 'link') {
			goto(gcinfo.url);
		}
		return gcinfo;
	}
</script>