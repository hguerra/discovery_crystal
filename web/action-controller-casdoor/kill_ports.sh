kill_port() {
    if [ -z "$1" ]; then
        echo "Usage: k <port_number>"
        return 1
    fi

    PORT=$1
    PIDS=$(lsof -t -i:"$PORT")

    if [ -z "$PIDS" ]; then
        echo "No processes found running on port $PORT"
        return 0
    fi

    echo "Killing processes on port $PORT: $PIDS"
    kill -9 $PIDS
}

kill_port 3000
