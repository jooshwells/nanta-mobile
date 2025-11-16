import app from "./app.js";
import connect_database from "./config/database.js";

const port = process.env.PORT || 8080;
const start_server = async () => {
    await connect_database();

    app.listen(port || 8080, () => {
        console.log(`Server listening on port ${port}`);
    });
};

start_server();