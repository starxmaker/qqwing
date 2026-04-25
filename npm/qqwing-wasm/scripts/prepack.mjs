import { copyFile, access } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const checkExistence = async (resourcePath) => {
    try {
        await access(resourcePath);
    } catch {
        throw new Error(
            `File not found at ${resourcePath}. Make sure you compile it first.`
        );
    }
};

const copyRequiredFile = async (sourcePath, destinationPath) => {
    await checkExistence(sourcePath);
    await copyFile(sourcePath, destinationPath);
};


const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const packageDir = path.resolve(scriptDir, '..');
const repoRoot = path.resolve(packageDir, '..', '..');

const wasmSource = path.join(repoRoot, 'target', 'wasm', 'main.wasm');
const wasmDestination = path.join(packageDir, 'main.wasm');
await copyRequiredFile(wasmSource, wasmDestination);

const jsSource = path.join(repoRoot, 'target', 'wasm', 'main.js');
const jsDestination = path.join(packageDir, 'main.js');
await copyRequiredFile(jsSource, jsDestination);

const dtsSource = path.join(repoRoot, 'target', 'wasm', 'main.d.ts');
const dtsDestination = path.join(packageDir, 'main.d.ts');
await copyRequiredFile(dtsSource, dtsDestination);

const licenseSource = path.join(repoRoot, 'doc', 'COPYING');
const licenseDestination = path.join(packageDir, 'LICENSE');
await copyRequiredFile(licenseSource, licenseDestination);