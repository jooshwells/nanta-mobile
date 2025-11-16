export const normalize_response = (request, response, next) => {
  response.success = (data = {}, message, status) => {
    return response.status(status).json({
      success: true,
      data: data,
      message,
    });
  };

  response.error = (errors = {}, message, status) => {
    return response.status(status).json({
      success: false,
      errors: errors,
      message,
    });
  };

  next();
};

export const normalize_system_error_response = (error, response) => {
  console.error("System error", error.stack || error);

  const status = error.status || error.statusCode || 500;

  return response.status(status).json({
    success: false,
    message: "Internal server error. Please try again later.",
  });
};

export const normalize_response_404 = (request, response, next) => {
  return response.status(404).json({
    success: false,
    message: "Not Found",
  });
};
