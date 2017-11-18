const fs = require('fs-extra');
const path = require('path');
const { URL } = require('url');
const EOL = require('os').EOL;
const adapters = { 'http:': require('http'), 'https:': require('https') };
const colorCodes = { 'cyan': 36, 'red': 31, 'green': 32, 'yellow': 33};
const colorize = (msg, color) => '\x1b[' + colorCodes[color] + 'm' + msg + '\x1b[0m';

function echo(msg, color, close, url) {
    process.stdout.cursorTo(0);
    process.stdout.write(colorize(msg.padEnd(13), color));
    if (url)    process.stdout.write(url);
    if (close)  process.stdout.write(EOL);
}

function downloadProm(currUrl, destdir, localPath) {
    echo('DOWNLOADING', 'yellow', false, currUrl.href);
    fs.ensureDirSync(destdir);

    return new Promise((resolve, reject) => {
        adapters[currUrl.protocol].get(currUrl.href, (res) => {
            let data = [];
            if (res.statusCode === 200) {
                let localMod = 0;
                try {
                    const stats = fs.statSync(localPath);
                    localMod = new Date(stats.mtime).getTime();
                }
                catch(e) {}
                const remoteMod = new Date(res.headers['last-modified']).getTime() || 0;

                if (remoteMod < localMod) {
                    echo('SKIPPED', 'cyan', true);
                    reject('');
                }

                res.on('data', (chunk) => data.push(chunk));
                res.on('end', () => resolve(Buffer.concat(data)));
                res.on('error', () => reject('Response ' + err));
            }
            else {
                echo('NOT FOUND', 'red', true);
                reject('');
            }
        }).on('error', (err) => reject('Request ' + err));
    })
}

function download(url) {
    const currUrl = new URL(url);
    const pathname = currUrl.pathname;
    const filename = path.basename(pathname);
    const destdir = path.resolve(path.join(__dirname, 'backup', path.dirname(pathname)));
    const localPath = path.join(destdir, filename);

    return downloadProm(currUrl, destdir, localPath)
        .then(data => {
            const fd = fs.openSync(localPath, 'w');
            fs.writeFileSync(fd, data);
            fs.closeSync(fd);
            echo('DOWNLOADED', 'green', true);
        })
        .catch((e) => {});
}

async function backupMediaLibrary() {
    const xml = fs.readFileSync('./export.xml').toString();
    const re = /<wp:attachment_url>(.+)<\/wp:attachment_url>/g;
    let match, urls = [];
    while (match = re.exec(xml)) urls.push(match[1]);

    if (!urls.length) {
        echo('No URLs found', 'red', true);
        return;
    }

    console.time('Total download time');
    for (let url of urls) await download(url);
    console.log('---');
    console.timeEnd('Total download time');
}

backupMediaLibrary();
