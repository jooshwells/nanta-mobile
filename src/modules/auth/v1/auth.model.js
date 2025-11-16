import mongoose from "mongoose";

const user_schema = new mongoose.Schema(
    {
        first_name: { type: String, required: true },
        last_name: { type: String, required: true },
        email: { type: String, required: true, unique: true },
        password: { type: String, required: true },
        is_verified: { type: Boolean, default: false },
        verification_token: { type: String, default: null }
    },
    {
        timestamps: {
            createdAt: "created_at",
            updatedAt: "updated_at"
        }
    }
);

const User = mongoose.model("User", user_schema);

export default User;