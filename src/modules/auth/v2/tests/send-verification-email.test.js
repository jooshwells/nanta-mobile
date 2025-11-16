import mongoose from 'mongoose';
import { describe, it, beforeAll, afterAll, afterEach, expect } from 'vitest';
import request from "supertest";
import app from "../../../../app.js";
import User from '../auth.model.js';
import bcrypt from 'bcryptjs';
import jwt from "jsonwebtoken";

describe("send verification email", () => {
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
                // await mongoose.connect("mongodb://mongo:27017/verify-email-test");
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

    afterEach(async () => {
        await User.deleteMany();
    });


    it("Send verification email \| verification email sent \(ok\)", async () => {
        /* Real response */
        const login_response = await request(app)
        .post("/api/auth/login")
        .send({
            email: "johndoe@example.com",
            password: "password123",
        });

        /* Real response cookie */
        const session_cookie = login_response.headers["set-cookie"];

        const response = await request(app)
        .post("/api/auth/user/verify-email/resend")
        .set("Cookie", session_cookie);        

        expect(response.statusCode).toBe(200);
        expect(response.body).toHaveProperty("email_status", "Sent");
    });
});