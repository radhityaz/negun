package middleware

import (
	"net/http"
	"os"

	"github.com/gin-gonic/gin"
)

func AdminAuth() gin.HandlerFunc {
	return func(c *gin.Context) {
		// Get Secret from Env
		secret := os.Getenv("ADMIN_SECRET")
		if secret == "" {
			// If not configured, block everything for safety
			c.AbortWithStatusJSON(http.StatusInternalServerError, gin.H{"error": "Server security misconfiguration"})
			return
		}

		// Check Header
		authHeader := c.GetHeader("X-Admin-Secret")
		if authHeader != secret {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized access"})
			return
		}

		c.Next()
	}
}
