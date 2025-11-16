import mongoose from "mongoose";

const connect_database = async () => {
    try 
    {
        await mongoose.connect(process.env.MONGO_URI);
        console.log("Connected to database!");
    } 
    catch (error) 
    {
        console.error(error);
        process.exit(1);
    }
}

export default connect_database;