import mongoose from 'mongoose';
import { describe, it, beforeAll, afterAll, afterEach, expect } from 'vitest';
import request from "supertest";
import app from "../../../../app.js";
import User from '../auth.model.js';


// describe("/api/auth/register", () => {
describe("/api/auth/register", () => {
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
                // await mongoose.connect("mongodb://mongo:27017/register-test");
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
        await User.deleteMany({});
    });

    it("successful registration (ok)", async () => {
        const response = await request(app)
            .post("/api/auth/register")
            .send({
                first_name: "John",
                last_name: "Doe",
                email: "johndoe@example.com",
                password: "password123",
                confirm_password: "password123"
            });

        expect(response.statusCode).toBe(200);
        expect("User registered successfully!");
    });

    it("missing first name (err)", async () => {
        const response = await request(app)
            .post("/api/auth/register")
            .send({
                // first_name: "John",
                last_name: "Doe",
                email: "johndoe@example.com",
                password: "password123",
                confirm_password: "password123"
            });

        expect(response.statusCode).toBe(400);
        expect(response.body.errors.first_name).toHaveProperty("msg", "Please enter your first name");
    });

    it("missing last name (err)", async () => {
        const response = await request(app)
            .post("/api/auth/register")
            .send({
                first_name: "John",
                // last_name: "Doe",
                email: "johndoe@example.com",
                password: "password123",
                confirm_password: "password123"
            });

        expect(response.statusCode).toBe(400);
        expect(response.body.errors.last_name).toHaveProperty("msg", "Please enter your last name");
    });

    it("missing email (err)", async () => {
        const response = await request(app)
            .post("/api/auth/register")
            .send({
                first_name: "John",
                last_name: "Doe",
                // email: "johndoe@example.com",
                password: "password123",
                confirm_password: "password123"
            });

        expect(response.statusCode).toBe(400);
        expect(response.body.errors.email).toHaveProperty("msg", "Please enter your email");
    });

    it("not an email (err)", async () => {
        const response = await request(app)
            .post("/api/auth/register")
            .send({
                first_name: "John",
                last_name: "Doe",
                email: "johndoeexample.com",
                password: "password123",
                confirm_password: "password123"
            });

        expect(response.statusCode).toBe(400);
        expect(response.body.errors.email).toHaveProperty("msg", "Please enter a valid email");
    });

    it("duplicate email (err)", async () => {
        /* Direct database insert */
        const user = await User.create({
            first_name: "John",
            last_name: "Doe",
            email: "johndoe@example.com",
            password: "password123",
            confirm_password: "password123"
        });

        /* Registration request */
        // await request(app)
        //     .post("/api/auth/register")
        //     .send({
        //         first_name: "John",
        //         last_name: "Doe",
        //         email: "johndoe@example.com",
        //         password: "password123",
        //         confirm_password: "password123"
        //     });

        const response = await request(app)
            .post("/api/auth/register")
            .send({
                first_name: "John",
                last_name: "Doe",
                email: "johndoe@example.com",
                password: "password123",
                confirm_password: "password123"
            });

        expect(response.statusCode).toBe(400);
        expect(response.body.errors.email).toHaveProperty("msg", "Email is already registered");

        await user.deleteOne();
    });

    it("missing password (err)", async () => {
        const response = await request(app)
            .post("/api/auth/register")
            .send({
                first_name: "John",
                last_name: "Doe",
                email: "johndoe@example.com",
                // password: "password123",
                confirm_password: "password123"
            });

        expect(response.statusCode).toBe(400);
        expect(response.body.errors.password).toHaveProperty("msg", "Please enter your password");
    });

    it("password less than 8 characters (err)", async () => {
        const response = await request(app)
            .post("/api/auth/register")
            .send({
                first_name: "John",
                last_name: "Doe",
                email: "johndoe@example.com",
                password: "passwor",
                confirm_password: "password"
            });

        expect(response.statusCode).toBe(400);
        expect(response.body.errors.password).toHaveProperty("msg", "Password must be at least 8 characters");
    });

    it("missing password confirmation (err)", async () => {
        const response = await request(app)
            .post("/api/auth/register")
            .send({
                first_name: "John",
                last_name: "Doe",
                email: "johndoe@example.com",
                password: "password123",
                // confirm_password: "password123"
            });

        expect(response.statusCode).toBe(400);
        expect(response.body.errors.confirm_password).toHaveProperty("msg", "Please confirm your password");
    });
})