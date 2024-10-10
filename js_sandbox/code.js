function pingIP(ip) {
    const urlsToCheck = [
        `http://${ip}/`
    ];

    const timeout = 100;  // 100 milliseconds timeout

    // Function to fetch URL and determine response
    const fetchUrl = (url) => {
        return Promise.race([
            fetch(url, { method: 'GET' })
                .then(response => {
                    console.log(response);
                    // Check if the status is within the success range
                    if (response.status >= 200 && response.status < 300) {
                        return { ip: ip, status: 'responded' };
                    } else {
                        return { ip: ip, status: 'no response' };
                    }
                })
                .catch(error => {
                    // Handle fetch-specific errors
                   // console.log(error.message);
                    if (error.message.includes('CORS')) {
                        return { ip: ip, status: 'responded' };  // Consider CORS errors as responded
                    }
                    return { ip: ip, status: 'no response' };
                }),

            new Promise((_, reject) => setTimeout(() => reject(new Error('timeout')), timeout))
                .then(() => ({ ip: ip, status: 'timeout' }))
                .catch(() => ({ ip: ip, status: 'timeout' }))
        ]);
    };

    // Process URLs and return result
    return Promise.all(urlsToCheck.map(url => fetchUrl(url)))
        .then(results => results.find(result => result.status === 'responded') || { ip: ip, status: 'no response' });
}

async function scanNetwork() {
    const baseIPs = [
        '192.168.4.'
        //'192.168.0.', '192.168.1.', '192.168.2.', '192.168.3.', '192.168.4.', '192.168.16.', // Common home networks
        //'10.0.0.', '10.0.1.', '10.1.1.'          // Common corporate networks
    ];
    
    const devices = [];

    // Loop through the common IP ranges and try pinging common device addresses
    for (const baseIP of baseIPs) {
        i = 0;
        while(1){  // Scan from .1 to .254
            const ip = `${baseIP}${i}`;
            const result = await pingIP(ip);
            if (result.status === 'responded') {
                
                console.log(`Device found at ${ip}`);
                break;
            }
            console.log(i);
            i++;
            if(i > 255){break};
        }
        devices.push(baseIP);
    }
    
    return devices;
}

// Start the scan
scanNetwork().then((devices) => {
    console.log("Found devices:", devices);
});

