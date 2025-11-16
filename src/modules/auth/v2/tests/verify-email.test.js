import mongoose from 'mongoose';
import { describe, it, beforeAll, beforeEach, afterAll, afterEach, expect } from 'vitest';
import request from "supertest";
import app from "../../../../app.js";
import User from '../auth.model.js';
import bcrypt from 'bcryptjs';
import jwt from "jsonwebtoken";

describe("/api/auth/verify-email", () => {
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
    });

    afterEach(async () => {
        await User.deleteMany();
    });

    it("Email verfication | email verified (ok)", async () => {
        /* Direct database insert */
        const user = await User.create({
            first_name: "John",
            last_name: "Doe",
            email: "johndoe@example.com",
            password: await bcrypt.hash("password123", 10)
        });
        
        const verification_token = jwt.sign(
            { type: "email-verification-token", user: { _id: user._id, email: user.email } }, 
            process.env.JWT_SECRET, 
            {expiresIn: '12h'}
        );  

        user.verification_token = verification_token;
        await user.save();

        const response = await request(app)
        .post("/api/auth/user/verify-email/" + verification_token)

        expect(response.statusCode).toBe(200);
        expect(response.body).toHaveProperty("verification_status", "Verified");
    });

    it("Email verfication | expired verification token (err)", async () => {
        /* Direct database insert */
        const user = await User.create({
            first_name: "John",
            last_name: "Doe",
            email: "johndoe@example.com",
            password: await bcrypt.hash("password123", 10)
        });
        
        const verification_token = jwt.sign(
            { type: "email-verification-token", user: { _id: user._id, email: user.email } }, 
            process.env.JWT_SECRET, 
            {expiresIn: -10}
        );  

        user.verification_token = verification_token;
        await user.save();

        const response = await request(app)
        .post("/api/auth/user/verify-email/" + verification_token)

        expect(response.statusCode).toBe(400);
        expect(response.body).toHaveProperty("verification_status", "Invalid token");
    });

    it("Email verfication | wrong token type (err)", async () => {
        /* Direct database insert */
        const user = await User.create({
            first_name: "John",
            last_name: "Doe",
            email: "johndoe@example.com",
            password: await bcrypt.hash("password123", 10)
        });
        
        const verification_token = jwt.sign(
            { type: "wrong-token", user: { _id: user._id, email: user.email } }, 
            process.env.JWT_SECRET, 
            {expiresIn: "12h"}
        );  

        user.verification_token = verification_token;
        user.save();

        const response = await request(app)
        .post("/api/auth/user/verify-email/" + verification_token)

        expect(response.statusCode).toBe(400);
        expect(response.body).toHaveProperty("verification_status", "Invalid token");
    });

    it("Email verfication | user does not exist (err)", async () => {
        /* Direct database insert */
        const user = await User.create({
            first_name: "John",
            last_name: "Doe",
            email: "johndoe@example.com",
            password: await bcrypt.hash("password123", 10)
        });
        
        const verification_token = jwt.sign(
            { type: "email-verification-token", user: { _id: user._id, email: user.email } }, 
            process.env.JWT_SECRET, 
            {expiresIn: '12h'}
        );  

        await user.deleteOne();

        const response = await request(app)
        .post("/api/auth/user/verify-email/" + verification_token)

        expect(response.statusCode).toBe(400);
        expect(response.body).toHaveProperty("verification_status", "Invalid token");
    });

    it("Email verfication | verification tokens do not match (err)", async () => {
        /* Direct database insert */
        const user = await User.create({
            first_name: "John",
            last_name: "Doe",
            email: "johndoe@example.com",
            password: await bcrypt.hash("password123", 10)
        });
        
        const verification_token = jwt.sign(
            { type: "email-verification-token", user: { _id: user._id, email: user.email } }, 
            process.env.JWT_SECRET, 
            {expiresIn: '12h'}
        );  

        user.verification_token = verification_token;
        await user.save();

        const response = await request(app)
        .post("/api/auth/user/verify-email/" + jwt.sign(
            { type: "email-verification-token", user: { _id: user._id, email: user.email }, nonsense: "gobbledegook" }, 
            process.env.JWT_SECRET, 
            {expiresIn: '12h'}
        ))
        expect(response.statusCode).toBe(400);
        expect(response.body).toHaveProperty("verification_status", "Invalid token");
    });
})