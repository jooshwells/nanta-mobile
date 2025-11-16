import mongoose from 'mongoose';
import { describe, it, beforeAll, afterAll, afterEach, expect } from 'vitest';
import request from "supertest";
import app from "../../../../app.js";
import User from '../auth.model.js';
import bcrypt from 'bcryptjs';
import jwt from "jsonwebtoken";

describe("/api/auth/user/authenticate", () => {
    beforeAll(async () => {
        try 
        {
            if (process.env.NODE_ENV === "production")
            {
                await mongoose.connect(process.env.MONGO_URI);
                console.log("Connected to production database `" + process.env.MONGO_URI + "`. Ready for testing!");
            }
            else
            {
                await mongoose.connect("mongodb://mongo:27017/test");
                console.log("Connected to test database `mongodb://mongo:27017/test`. Ready for testing!");
            }
        } 
        catch (error) 
        {
            console.error(error);
            process.exit(1);
        }

        await User.deleteMany();

        /* Direct database insert */
        const user = await User.create({
            first_name: "John",
            last_name: "Doe",
            email: "johndoe@example.com",
            password: await bcrypt.hash("password123", 10)
        });
    });

    afterAll(async () => {
        await User.deleteMany();
    });

    it("User authentication \| user authorized \(ok\)", async () => {
        const user = await User.findOne({ email: "johndoe@example.com" });

        const session_token = jwt.sign(
            { type: "session-token", user: { _id: user._id, email: user.email } },
            process.env.JWT_SECRET,
            { expiresIn: "12h" }
        );

        const cookie = "nanta-session=" + session_token;
        
        // /* Real response */
        // const login_response = await request(app)
        // .post("/api/auth/login")
        // .send({
        //     email: "johndoe@example.com",
        //     password: "password123",
        // });

        // /* Real response cookie */
        // const cookie = login_response.headers["set-cookie"];

        const response = await request(app)
        .get("/api/auth/user/authenticate")
        .set("Cookie", cookie);

        expect(response.statusCode).toBe(200);
        expect(response.body).toHaveProperty("authorization_status", "Authorized");
    });

    it("User authentication \| missing session token \(err\)", async () => {
        // const user = await User.findOne({ email: "johndoe@example.com" });

        // const session_token = jwt.sign(
        //     { type: "wrong-token", user: { _id: user._id, email: user.email } },
        //     process.env.JWT_SECRET,
        //     { expiresIn: "12h" }
        // );

        // const cookie = "nanta-session=" + session_token;

        const response = await request(app)
        .get("/api/auth/user/authenticate")
        // .set("Cookie", cookie)

        expect(response.statusCode).toBe(400);
        expect(response.body).toHaveProperty("authorization_status", "Unauthorized");
    });

    it("User authentication \| expired session token \(err\)", async () => {
        const user = await User.findOne({ email: "johndoe@example.com" });

        const session_token = jwt.sign(
            { type: "session-token", user: { _id: user._id, email: user.email } },
            process.env.JWT_SECRET,
            { expiresIn: -10 }
        );

        const cookie = "nanta-session=" + session_token;

        const response = await request(app)
        .get("/api/auth/user/authenticate")
        .set("Cookie", cookie)

        expect(response.statusCode).toBe(400);
        expect(response.body).toHaveProperty("authorization_status", "Unauthorized");
    });

    it("User authentication \| wrong token type \(err\)", async () => {
        const user = await User.findOne({ email: "johndoe@example.com" });

        const session_token = jwt.sign(
            { type: "wrong-token", user: { _id: user._id, email: user.email } },
            process.env.JWT_SECRET,
            { expiresIn: "12h" }
        );

        const cookie = "nanta-session=" + session_token;

        const response = await request(app)
        .get("/api/auth/user/authenticate")
        .set("Cookie", cookie)

        expect(response.statusCode).toBe(400);
        expect(response.body).toHaveProperty("authorization_status", "Unauthorized");
    });

    it("User authentication \| user does not exist \(err\)", async () => {
        const session_token = jwt.sign(
            { type: "session-token", user: { _id: new mongoose.Types.ObjectId("123456781234567812345678"), email: "nonexistent@example.com" } },
            process.env.JWT_SECRET,
            { expiresIn: "12h" }
        );

        const cookie = "nanta-session=" + session_token;

        const response = await request(app)
        .get("/api/auth/user/authenticate")
        .set("Cookie", cookie)

        expect(response.statusCode).toBe(400);
        expect(response.body).toHaveProperty("authorization_status", "Unauthorized");
    }); 
})