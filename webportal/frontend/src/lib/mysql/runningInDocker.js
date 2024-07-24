
let inDocker = process.env.DOCKERNAME;

export function runningInDocker() {
    return inDocker;
}
