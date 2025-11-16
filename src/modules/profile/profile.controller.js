import { normalize_system_error_response } from "../../custom.middleware.js";
import User from "../auth/v2/auth.model.js";
import bcrypt from "bcryptjs";

export const update_profile = async (request, response) => {
  try {
    const user_id = request.user && (request.user.id || request.user._id);

    if (!user_id) {
      return response
        .status(401)
        .json({ request, message: "User not authenticated!" });
    }

    const { first_name, last_name, email, password, profile_pic } =
      request.body;

    const updateFields = {};
    if (first_name) updateFields.first_name = first_name;
    if (last_name) updateFields.last_name = last_name;
    if (email) updateFields.email = email;

    if (profile_pic !== undefined) {
      updateFields.profile_pic = profile_pic;
    }

    if (password) {
      if (password.length < 8) {
        return response
          .status(400)
          .json({ message: "Password must be at least 8 characters." });
      }
      updateFields.password = await bcrypt.hash(password, 10);
    }

    const updatedUser = await User.findByIdAndUpdate(
      user_id,
      { $set: updateFields },
      {
        new: true,
        runValidators: true,
      }
    ).select("-password");

    if (!updatedUser) {
      return response.status(404).json({ message: "User not found." });
    }

    return response.status(200).json({
      message: "Profile updated successfully!",
      user: updatedUser.toObject(),
    });
  } catch (error) {
    normalize_system_error_response(error, response);
  }
};
