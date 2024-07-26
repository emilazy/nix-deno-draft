import * as path from "https://deno.land/std@0.191.0/path/mod.ts";
import { toHashString } from "https://deno.land/std@0.191.0/crypto/to_hash_string.ts";
import { ensureSymlink } from "https://deno.land/std@0.191.0/fs/mod.ts";

interface Attrs {
	readonly outputs: { readonly out: string };
	readonly denoDeps: {
		readonly url: string;
		readonly downloadPath: string;
	}[];
}

const attrs: Attrs = JSON.parse(await Deno.readTextFile(".attrs.json"));

async function cachePaths(
	url: URL,
): Promise<{ cachePath: string; cacheMetadataPath: string }> {
	const protocol = url.protocol.replace(/:$/, "");
	const host = url.host.replace(":", "_PORT");

	const pathBuffer = new TextEncoder().encode(url.pathname + url.search);
	const pathHashBuffer = await crypto.subtle.digest("SHA-256", pathBuffer);
	const pathHash = toHashString(pathHashBuffer);

	const dir = path.join(attrs.outputs.out, protocol, host);

	return {
		cachePath: path.join(dir, pathHash),
		cacheMetadataPath: path.join(dir, pathHash + ".metadata.json"),
	};
}

for (const dep of attrs.denoDeps) {
	const { cachePath, cacheMetadataPath } = await cachePaths(
		new URL(dep.url),
	);

	console.log(`${dep.downloadPath} -> ${cachePath}`);

	const metadata = {
		url: dep.url,
		// TODO: save headers?
		// deno looks at content-type...
		headers: {}, // { "content-type": "appilcation/json" },
	};

	await ensureSymlink(dep.downloadPath, cachePath);
	await Deno.writeTextFile(cacheMetadataPath, JSON.stringify(metadata));
}
